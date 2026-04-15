import '../database.dart';

class ProfilesPrivInfoTable extends SupabaseTable<ProfilesPrivInfoRow> {
  @override
  String get tableName => 'profiles_priv_info';

  @override
  ProfilesPrivInfoRow createRow(Map<String, dynamic> data) =>
      ProfilesPrivInfoRow(data);
}

class ProfilesPrivInfoRow extends SupabaseDataRow {
  ProfilesPrivInfoRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ProfilesPrivInfoTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get branchId => getField<String>('branch_id')!;
  set branchId(String value) => setField<String>('branch_id', value);

  String? get departmentId => getField<String>('department_id');
  set departmentId(String? value) => setField<String>('department_id', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String get fullName => getField<String>('full_name')!;
  set fullName(String value) => setField<String>('full_name', value);

  String? get phone => getField<String>('phone');
  set phone(String? value) => setField<String>('phone', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get membershipCode => getField<String>('membership_code');
  set membershipCode(String? value) =>
      setField<String>('membership_code', value);

  DateTime? get dateJoined => getField<DateTime>('date_joined');
  set dateJoined(DateTime? value) => setField<DateTime>('date_joined', value);

  bool? get verified => getField<bool>('verified');
  set verified(bool? value) => setField<bool>('verified', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get dob => getField<DateTime>('dob');
  set dob(DateTime? value) => setField<DateTime>('dob', value);

  String? get occupation => getField<String>('occupation');
  set occupation(String? value) => setField<String>('occupation', value);

  String? get address => getField<String>('address');
  set address(String? value) => setField<String>('address', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  String? get avatar => getField<String>('avatar');
  set avatar(String? value) => setField<String>('avatar', value);

  String? get lastname => getField<String>('lastname');
  set lastname(String? value) => setField<String>('lastname', value);

  String? get firstname => getField<String>('firstname');
  set firstname(String? value) => setField<String>('firstname', value);

  bool? get profilecomplete => getField<bool>('profilecomplete');
  set profilecomplete(bool? value) => setField<bool>('profilecomplete', value);

  String? get prefix => getField<String>('prefix');
  set prefix(String? value) => setField<String>('prefix', value);

  DateTime? get dateOfBirth => getField<DateTime>('date_of_birth');
  set dateOfBirth(DateTime? value) =>
      setField<DateTime>('date_of_birth', value);

  String? get gender => getField<String>('gender');
  set gender(String? value) => setField<String>('gender', value);

  String? get maritalStatus => getField<String>('marital_status');
  set maritalStatus(String? value) => setField<String>('marital_status', value);

  String? get phoneNumber => getField<String>('phone_number');
  set phoneNumber(String? value) => setField<String>('phone_number', value);

  String? get residentialAddress => getField<String>('residential_address');
  set residentialAddress(String? value) =>
      setField<String>('residential_address', value);

  DateTime? get dateJoinedWpcc => getField<DateTime>('date_joined_wpcc');
  set dateJoinedWpcc(DateTime? value) =>
      setField<DateTime>('date_joined_wpcc', value);

  DateTime? get waterBaptismDate => getField<DateTime>('water_baptism_date');
  set waterBaptismDate(DateTime? value) =>
      setField<DateTime>('water_baptism_date', value);

  String? get maturityClassCompleted =>
      getField<String>('maturity_class_completed');
  set maturityClassCompleted(String? value) =>
      setField<String>('maturity_class_completed', value);

  String? get ministryClassCompleted =>
      getField<String>('ministry_class_completed');
  set ministryClassCompleted(String? value) =>
      setField<String>('ministry_class_completed', value);

  String? get missionClassCompleted =>
      getField<String>('mission_class_completed');
  set missionClassCompleted(String? value) =>
      setField<String>('mission_class_completed', value);

  String? get emergencyContact => getField<String>('emergency_contact');
  set emergencyContact(String? value) =>
      setField<String>('emergency_contact', value);
}
