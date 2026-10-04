"""Run over SSH on the self-hosted Supabase server. Creates and removes only its own fixtures.
Credentials are read in memory from the existing container; never printed or persisted.
"""
import subprocess,json,urllib.request,urllib.error,uuid,base64,secrets,hmac,hashlib,datetime,urllib.parse
raw=json.loads(subprocess.check_output(['docker','inspect','supabase-edge-functions']))[0]['Config']['Env']
env=dict(e.split('=',1) for e in raw)
key=env['SUPABASE_SERVICE_ROLE_KEY']
binding=json.loads(subprocess.check_output(['docker','inspect','supabase-envoy']))[0]['NetworkSettings']['Ports']['8000/tcp'][0]
base='http://'+binding['HostIp']+':'+binding['HostPort']
users=[]
objects=[]
def request(path,data=None,token=None,method=None,ctype='application/json'):
    headers={'apikey':key,'Authorization':'Bearer '+(token or key),'Content-Type':ctype,'User-Agent':'WPCC-Profile-Verification/1.0'}
    req=urllib.request.Request(base+path,data=json.dumps(data).encode() if isinstance(data,(dict,list)) else data,headers=headers,method=method)
    try:
        with urllib.request.urlopen(req,timeout=40) as response:return response.status,response.read()
    except urllib.error.HTTPError as error:return error.code,error.read()
def remove_object(url):
    bucket,objectkey=url[5:].split('/',1)
    host=env['R2_ACCOUNT_ID']+'.r2.cloudflarestorage.com'
    stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ');day=stamp[:8];scope=day+'/auto/s3/aws4_request'
    params={'X-Amz-Algorithm':'AWS4-HMAC-SHA256','X-Amz-Credential':env['R2_PRIVATE_ACCESS_KEY_ID']+'/'+scope,'X-Amz-Date':stamp,'X-Amz-Expires':'300','X-Amz-SignedHeaders':'host'}
    query=urllib.parse.urlencode(sorted(params.items()),quote_via=urllib.parse.quote,safe='~')
    uri='/'+bucket+'/'+urllib.parse.quote(objectkey,safe='/~')
    canonical='DELETE\n'+uri+'\n'+query+'\nhost:'+host+'\n\nhost\nUNSIGNED-PAYLOAD'
    sign=lambda k,v:hmac.new(k,v.encode(),hashlib.sha256).digest()
    signing_key=sign(('AWS4'+env['R2_PRIVATE_SECRET_ACCESS_KEY']).encode(),day)
    for item in ['auto','s3','aws4_request']:signing_key=sign(signing_key,item)
    sig=sign(signing_key,'AWS4-HMAC-SHA256\n'+stamp+'\n'+scope+'\n'+hashlib.sha256(canonical.encode()).hexdigest()).hex()
    with urllib.request.urlopen(urllib.request.Request('https://'+host+uri+'?'+query+'&X-Amz-Signature='+sig,method='DELETE')) as response:assert response.status in (200,204)
try:
    status,body=request('/rest/v1/branches?select=id&limit=1');assert status==200,('branch',status)
    branch=json.loads(body)[0]['id'];tokens=[]
    for index in range(2):
        email='avatar-audit-'+str(uuid.uuid4())+'@example.invalid';password=secrets.token_urlsafe(32)
        status,body=request('/auth/v1/admin/users',{'email':email,'password':password,'email_confirm':True});assert status in (200,201),('create',status)
        uid=json.loads(body)['id'];users.append(uid)
        status,body=request('/rest/v1/profiles',{'id':uid,'branch_id':branch,'firstname':'Avatar','lastname':uid,'full_name':'Avatar '+uid});assert status in (200,201),('profile',status)
        status,body=request('/auth/v1/token?grant_type=password',{'email':email,'password':password});assert status==200,('login',status)
        tokens.append(json.loads(body)['access_token'])
    png=base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')
    boundary='avatar-test-'+uuid.uuid4().hex
    def upload(data,filename='avatar.png'):
        body=('--'+boundary+'\r\nContent-Disposition: form-data; name="file"; filename="'+filename+'"\r\nContent-Type: image/png\r\n\r\n').encode()+data+('\r\n--'+boundary+'--\r\n').encode()
        return request('/functions/v1/profile-avatar',body,tokens[0],ctype='multipart/form-data; boundary='+boundary)
    status,body=upload(png)
    if status!=200:
        print('Upload failure:',status,body.decode()[:200]);raise RuntimeError('Upload failed')
    url=json.loads(body)['avatar_url'];objects.append(url);print('Authenticated PNG upload: PASS')
    status,body=request('/functions/v1/profile-avatar',{'avatar_url':url,'include_data':True},tokens[0]);assert status==200,('own read',status)
    assert base64.b64decode(json.loads(body)['data_base64'])==png;print('Owner reads original bytes: PASS')
    status,_=request('/functions/v1/profile-avatar',{'avatar_url':url,'include_data':True},tokens[1]);assert status==404,('cross-user',status);print('Unrelated member denied: PASS')
    status,_=request('/functions/v1/profile-avatar',{},'invalid-token');assert status==401;print('Invalid session denied: PASS')
    status,_=upload(b'<svg xmlns="http://www.w3.org/2000/svg"/>','fake.png');assert status==415,('invalid format',status);print('Disguised SVG denied: PASS')
    status,_=upload(png+b'0'*(5*1024*1024));assert status==413,('size',status);print('Oversized image denied: PASS')
    status,body=upload(png);assert status==200;objects.append(json.loads(body)['avatar_url'])
    status,_=request('/functions/v1/profile-avatar',{'avatar_url':url,'include_data':True},tokens[0]);assert status==404;print('Replaced object inaccessible: PASS')
finally:
    for url in objects:remove_object(url)
    for uid in users:
        status,_=request('/auth/v1/admin/users/'+uid,method='DELETE');assert status==200
    print('Disposable fixtures cleaned up')
