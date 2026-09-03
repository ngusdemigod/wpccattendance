SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict xMXcD7pZx49r4P1qaLhXcEqeCWRYCFbJKiTgYPV3xMtEeZypxPGzJ2YgBVW4rcc

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

TRUNCATE TABLE
  public.attendance_audit_logs,
  public.attendance,
  public.comments,
  public.post_reactions,
  public.posts,
  public.departmental_events,
  public.branch_events,
  public.global_events,
  public.departmental_recurring_events,
  public.global_recurring_events,
  public.announcements,
  public.global_admins,
  public.leaders,
  public.workers,
  public.roles,
  public.otp_cooldowns,
  public.membershipcode,
  public.profiles_priv_info,
  public.profiles,
  public.leadership_titles,
  public.roletypes,
  public.departments,
  public.branches
RESTART IDENTITY CASCADE;

--
-- Data for Name: branches; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."branches" ("id", "name", "created_at", "slug", "address", "contactnumber", "lastmember", "prefix") VALUES
	('f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'His Glory Expression', '2026-03-07 10:06:59.517407', 'HGE', 'Road 4, plot 11', NULL, 0, 'WPCC/HQ/'),
	('5a65519c-cf68-4977-9e44-fc3f206ec9fb', 'Royalty Expression', '2026-03-01 17:45:55.915534', 'RE', 'No.1 Ada george Road, Location by wide choice, Portharcourt, Rivers State, Nigeria', '0900 000 0000', 0, 'WPCC/RE/');


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."departments" ("id", "name", "created_at", "description") VALUES
	('bd5f7833-cd47-48c7-8334-2c403d2d4aa0', 'Worship & Music', '2026-03-01 18:32:05.684082', 'Leads the congregation in spiritual worship and musical excellence.'),
	('252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Ushering & Protocol', '2026-03-01 18:32:05.684082', 'Ensures order and comfort during services and assists officiating ministers.'),
	('02d644fe-acd7-416f-aba1-6c9ccf4a7904', 'Prayer & Intercession', '2026-03-01 18:32:05.684082', 'Focuses on spiritual warfare, morning devotions, and prayer marathons.'),
	('021b4b42-59ea-46dd-aca3-59863eab53d1', 'Evangelism & Outreach', '2026-03-01 18:32:05.684082', 'Drives church expansion through community missions and outdoor activities.'),
	('5ee5c21b-9382-4992-8687-b732980f30f6', 'Youth & Teen Ministry', '2026-03-01 18:32:05.684082', 'Focuses on career development and spiritual growth for the Switch Generation.'),
	('46c85893-3953-4337-84f9-edb1806b0669', 'Pastorate', '2026-03-21 12:52:18', 'Pastorate department'),
	('e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'Power House', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Wisdom Streams', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('49831aa5-ffbe-44f3-bc8f-6e639553474e', 'Welfare', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('2ddfe8b3-72c7-49d6-9450-588ce6d72ed3', 'Directorate of Works', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('049bd00b-a053-4a36-9c22-415f477f172e', 'ICARE', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('777796f6-7ea3-4ceb-a95b-eafcf573bc9f', 'Transport', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('d94730d7-4ee6-4e40-83c4-573ffe0c6e1d', 'Security', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'Sanctuary', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('d018f62a-e916-42c6-bcba-cb3fd4546162', 'Decoration', '2026-04-07 18:14:40.491456', 'Auto-created from Excel'),
	('a4bb9e51-b105-43a9-801c-14dd4ad60c1d', 'Accounts', '2026-04-08 09:12:38.016858', NULL),
	('e14a403b-9739-45ef-8a24-b90866749318', 'Children''s Department', '2026-04-08 09:12:38.016858', NULL),
	('dcea05e8-fc39-4851-935c-808643593c73', 'Media & Technical', '2026-04-08 09:12:38.016858', NULL),
	('e77360af-516c-4f9f-8649-65b128d2c03c', 'Creativity', '2026-04-08 09:12:38.016858', NULL),
	('23d94616-5401-45f5-94b8-c86584de853e', 'Life Plus Church', '2026-04-08 09:12:38.016858', NULL);


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."profiles" ("id", "branch_id", "department_id", "full_name", "phone", "bio", "membership_code", "date_joined", "verified", "created_at", "avatar", "lastname", "firstname", "prefix", "email") VALUES
	('62f487e2-453a-428c-91ba-66349cc82251', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '46c85893-3953-4337-84f9-edb1806b0669', 'Adeshina Gentry', '08064134853', 'Global Lead Pastor, Wisdom Power Christian Centre', '0001', '2026-05-01', true, '2026-05-01 04:26:59.976592', 'https://scontent.fiba2-3.fna.fbcdn.net/v/t39.30808-6/241991601_10220154718084302_7019413582117396726_n.jpg?_nc_cat=111&ccb=1-7&_nc_sid=1d70fc&_nc_eui2=AeFMxdMvTDGH-SDd4PB1_DdHF7O-vZAAp6YXs769kACnprRICpKLqh1f_ASDRcM4nkMLxvyYACDyJVCju4i_faHU&_nc_ohc=E3fzZqFpeAwQ7kNvwFGLfyy&_nc_oc=AdquoSmExSZXslM8x7V34D29Nn7cSAqtedKxvTFB5iN4apdmu_FAS_7en_B9Uaj3-vQ&_nc_zt=23&_nc_ht=scontent.fiba2-3.fna&_nc_gid=xLZeWkVZqB3AlpSTK60Ehg&_nc_ss=7b2a8&oh=00_Af6woEBvmME1ij3ftdV1vqFVrGLkjgTE5YsWFMG89AnDPg&oe=69FA08E8', 'Adeshina', 'Gentry', 'WPCC/HQ/', NULL),
	('c93c9406-5404-4822-8749-62761ff285f2', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '049bd00b-a053-4a36-9c22-415f477f172e', 'Igbani Angus Claude', '+2348012345678', 'Passionate about using visual arts to spread the gospel.', 'RE-00401', '2026-03-01', true, '2026-03-01 18:34:29.055484', NULL, 'igbani', 'angus', 'WPCC/HQ/', NULL),
	('fa4b9146-3e7d-5466-a2fb-0a3fb4f7634b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Moshood Aminat Fumilayo', '8181244117', NULL, '0076', '2026-04-08', false, '2026-04-08 07:16:59.114499', NULL, 'Aminat Fumilayo', 'Moshood', 'WPCC/HQ/', NULL),
	('4388937c-0663-5c19-9326-df1497aae772', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Moshood Aisha O.', '8144147344', NULL, '0077', '2024-05-01', false, '2026-04-08 07:16:59.114499', NULL, 'Aisha O.', 'Moshood', 'WPCC/HQ/', NULL),
	('5528e385-375b-53db-baa4-fcde2f4f7206', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'Igwe Elijah Isaiah', '8064047217.0', NULL, '0017', '2009-09-18', false, '2026-04-07 21:33:10.567939', NULL, 'Elijah Isaiah', 'Igwe', 'WPCC/HQ/', NULL),
	('a1ab1dba-c790-5afe-89ae-2cab65f2f0c0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Siminialaiyim Flourish Apollos', '7017229158', NULL, '0058', '2026-04-07', false, '2026-04-07 21:42:01.573109', NULL, 'Flourish Apollos', 'Siminialaiyim', 'WPCC/HQ/', NULL),
	('20d88ef5-cbf9-510b-aa82-eb06ba097b6a', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Uchechi Godspower Godwin', '8033100652', NULL, '0063', '2026-04-07', false, '2026-04-07 21:42:33.60788', NULL, 'Godspower Godwin', 'Uchechi', 'WPCC/HQ/', NULL),
	('11e9782c-3d90-53df-a276-5809d8e22197', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Balogun Yemisi', '8167602331.0', NULL, '0079', '2026-04-08', false, '2026-04-08 07:18:17.835044', NULL, 'Yemisi', 'Balogun', 'WPCC/HQ/', NULL),
	('9c13f991-e95c-5b4b-9c8c-b5aecd907a3a', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Grace Seifegha Warri Ebi', '7030004803.0', NULL, '0042', '2026-04-07', false, '2026-04-07 21:33:10.567939', NULL, 'Seifegha Warri Ebi', 'Grace', 'WPCC/HQ/', NULL),
	('c9a2840c-c6c6-5f77-8d83-515fc1f944dc', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Siminialaiyim Conqueror Apollos', '8100514217.0', NULL, '0109', '2026-04-08', false, '2026-04-08 07:21:47.544856', NULL, 'Conqueror Apollos', 'Siminialaiyim', 'WPCC/HQ/', NULL),
	('dc6f0db4-4c33-5a1f-9efd-456e0fecebf8', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Favour Abbey', '8032758696', NULL, '0050', '2026-04-07', false, '2026-04-07 21:42:01.573109', NULL, 'Abbey', 'Favour', 'WPCC/HQ/', NULL),
	('a00f4b5b-696e-5810-a7b1-1fe1d5303198', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Hope Saturday Nuka', '9031763784', NULL, '0051', '2026-04-07', false, '2026-04-07 21:42:01.573109', NULL, 'Saturday Nuka', 'Hope', 'WPCC/HQ/', NULL),
	('fd46d9f0-567f-59ac-870a-289308fb0537', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Eniye Ehighakwo', '8036829274', NULL, '0072', '2026-04-08', false, '2026-04-08 07:16:59.114499', NULL, 'Ehighakwo', 'Eniye', 'WPCC/HQ/', NULL),
	('9bb5cc87-d189-5067-9947-93d95e4ae873', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Esther Adaeze Michael', '8169395893', NULL, '0057', '2026-04-07', false, '2026-04-07 21:42:01.573109', NULL, 'Adaeze Michael', 'Esther', 'WPCC/HQ/', NULL),
	('7de1a2ec-cd94-5f4a-894c-5b663bf32a99', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Joyce Okah', '8037774998', NULL, '0060', '2026-04-07', false, '2026-04-07 21:42:01.573109', NULL, 'Okah', 'Joyce', 'WPCC/HQ/', NULL),
	('f837bd63-9f89-53b1-91a5-8e99446d1bf9', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Omuku Patience', '7025816990', NULL, '0061', '2026-04-07', false, '2026-04-07 21:42:33.60788', NULL, 'Patience', 'Omuku', 'WPCC/HQ/', NULL),
	('6c400f3e-a082-5371-b4d6-1a924fd575f4', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Bolawatife Moshood', '9037491756.0', NULL, '0082', '2026-04-08', false, '2026-04-08 07:18:17.835044', NULL, 'Moshood', 'Bolawatife', 'WPCC/HQ/', NULL),
	('19197c6e-2404-53f2-b618-026745017abc', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Otoware Elizabeth', '7031391896.0', NULL, '0139', '2026-04-08', false, '2026-04-08 07:30:40.200729', NULL, 'Elizabeth', 'Otoware', 'WPCC/HQ/', NULL),
	('ae94c95c-a8e7-5546-a35d-053aa2cffed0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Ashira OlisaErike Presley', '7072377702.0', NULL, '0085', '2000-03-01', false, '2026-04-08 07:18:17.835044', NULL, 'OlisaErike Presley', 'Ashira', 'WPCC/HQ/', NULL),
	('d06a4ea7-0373-5cdf-9f4a-b66cc0f9c6f1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Kaleglia I Mercy', '8036661197.0', NULL, '0119', '2026-04-08', false, '2026-04-08 07:24:14.266395', NULL, 'I Mercy', 'Kaleglia', 'WPCC/HQ/', NULL),
	('7bfbf62d-d417-5d06-abed-6c922b4c8827', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Igbani Claudia Ibiye', '7042110762.0', NULL, '0088', '2026-03-11', false, '2026-04-08 07:18:17.835044', NULL, 'Claudia Ibiye', 'Igbani', 'WPCC/HQ/', NULL),
	('6f5def03-569a-5095-9201-c2626d894e70', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Esther Chibuzu Edwin', '7014145501.0', NULL, '0122', '2026-04-08', false, '2026-04-08 07:24:14.266395', NULL, 'Chibuzu Edwin', 'Esther', 'WPCC/HQ/', NULL),
	('d6354343-e7f2-5cb4-a4f1-e26cb99f1a30', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'Godsfavour iheanomachi', '9165710685.0', NULL, '0131', '2026-04-08', false, '2026-04-08 07:27:32.215241', NULL, 'iheanomachi', 'Godsfavour', 'WPCC/HQ/', NULL),
	('eee782a8-5009-5a7b-bff6-0be616e4b2f7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Ikechukwu Hope Isaac', '8088646081.0', NULL, '0138', '2026-04-08', false, '2026-04-08 07:30:40.200729', NULL, 'Hope Isaac', 'Ikechukwu', 'WPCC/HQ/', NULL),
	('b243ea46-f950-5c14-ab42-7c8dbc08fdf6', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Queen Elizabeth James Akyee', '9150707787.0', NULL, '0133', '2026-04-08', false, '2026-04-08 07:30:40.200729', NULL, 'Elizabeth James Akyee', 'Queen', 'WPCC/HQ/', NULL),
	('ee6e16f1-b774-5c48-bf9a-8489108e6be2', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '23d94616-5401-45f5-94b8-c86584de853e', 'Idu Daniella Chizi', '7039313765', NULL, '0073', '2026-04-08', false, '2026-04-08 07:16:59.114499', NULL, 'Daniella Chizi', 'Idu', 'WPCC/HQ/', NULL),
	('f585dde3-a79e-50c3-9aad-4c9f321f00b0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '02d644fe-acd7-416f-aba1-6c9ccf4a7904', 'Daniel Ademu', '8033342831.0', NULL, '0007', '2006-03-01', false, '2026-04-07 21:32:08.498107', NULL, 'Ademu', 'Daniel', 'WPCC/HQ/', NULL),
	('74b41b31-0adc-59b8-9693-4683560913fd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e14a403b-9739-45ef-8a24-b90866749318', 'Maris Agabi', '7067422153.0', NULL, '0034', '2026-04-07', false, '2026-04-07 21:32:39.050584', NULL, 'Agabi', 'Maris', 'WPCC/HQ/', NULL),
	('63625f49-e9fb-5571-80ab-b94a3044e8c5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Isaiah Awaji Moroiso Rejoice', '7015043018.0', NULL, '0043', '2026-04-07', false, '2026-04-07 21:40:51.818135', NULL, 'Awaji Moroiso Rejoice', 'Isaiah', 'WPCC/HQ/', NULL),
	('cf80d0e1-b26b-536a-b4a0-b25bc83ac591', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e14a403b-9739-45ef-8a24-b90866749318', 'Emmanuel Johnson', '9112949907.0', NULL, '0044', '2026-04-07', false, '2026-04-07 21:40:51.818135', NULL, 'Johnson', 'Emmanuel', 'WPCC/HQ/', NULL),
	('114ab3f4-0f8c-5f01-be8b-ecc32729cf87', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Nancy Azubuike', '8085978797.0', NULL, '0045', '2026-04-07', false, '2026-04-07 21:40:51.818135', NULL, 'Azubuike', 'Nancy', 'WPCC/HQ/', NULL),
	('4668c1ea-b2f0-51fa-a4d1-41096c6792f7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Zoe Ogor Godwin', '9054797669.0', NULL, '0047', '2026-04-07', false, '2026-04-07 21:40:51.818135', NULL, 'Ogor Godwin', 'Zoe', 'WPCC/HQ/', NULL),
	('82af049e-1ab6-5599-8805-728b6d081f21', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Peace Ajie', '8141208942', NULL, '0062', '2026-04-07', false, '2026-04-07 21:42:33.60788', NULL, 'Ajie', 'Peace', 'WPCC/HQ/', NULL),
	('5639f727-44f2-5177-ad54-8c8bb61864f1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Eboma Victory Ndu', '8143431980', NULL, '0054-1', '2026-04-07', false, '2026-04-07 21:42:33.60788', NULL, 'Victory Ndu', 'Eboma', 'WPCC/HQ/', NULL),
	('6262453e-52b0-5844-8da8-00a6f477eb3b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Okofor Gladys .E.', '7063162602', NULL, '0056-1', '2026-04-07', false, '2026-04-07 21:42:33.60788', NULL, 'Gladys .E.', 'Okofor', 'WPCC/HQ/', NULL),
	('db838aba-1c49-5517-90c7-0105342a392c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Unuafe Zue', '8069357062', NULL, '0065', '2026-04-07', false, '2026-04-07 21:43:04.328479', NULL, 'Zue', 'Unuafe', 'WPCC/HQ/', NULL),
	('27dfcf5e-5182-5882-9654-722a945eef50', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Faith Reuben', '9017684949', NULL, '0066', '2026-04-07', false, '2026-04-07 21:43:04.328479', NULL, 'Reuben', 'Faith', 'WPCC/HQ/', NULL),
	('93616239-014c-535e-9907-743cc3984e03', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Chinonyerem Benson', '7025816990', NULL, '0067', '2026-04-07', false, '2026-04-07 21:43:04.328479', NULL, 'Benson', 'Chinonyerem', 'WPCC/HQ/', NULL),
	('0bd73ba6-01a2-51a7-897d-606ecb6ee2f3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Godgift Ajie', '9031264875', NULL, '0068', '2026-04-07', false, '2026-04-07 21:43:04.328479', NULL, 'Ajie', 'Godgift', 'WPCC/HQ/', NULL),
	('d88ebca9-5481-55ec-8930-b5ee10fd9d39', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Esther Onyeche', '7025816990', NULL, '0069', '2026-04-07', false, '2026-04-07 21:43:04.328479', NULL, 'Onyeche', 'Esther', 'WPCC/HQ/', NULL),
	('7cd5e1ec-3cce-5f92-876d-c8acdd30a0d3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Anodere Chalya', '7066397104', NULL, '/HQ/', '2026-04-08', false, '2026-04-08 08:11:23.082382', NULL, 'Chalya', 'Anodere', 'WPCC/HQ/', NULL),
	('fcbded63-f969-5559-a25e-821a639be14c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'Mukoro Kesiena Abraham', '7038412469', NULL, '0146', '2026-04-08', false, '2026-04-08 08:11:23.082382', NULL, 'Kesiena Abraham', 'Mukoro', 'WPCC/HQ/', NULL),
	('f3732027-f05a-423c-a51a-ca2bda86b2f2', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', 'dcea05e8-fc39-4851-935c-808643593c73', 'Angus Igbani TT', '08182581363', 'Good boy', 'RE-00300', '2026-03-04', false, '2026-03-04 06:45:04.138221', 'https://media.licdn.com/dms/image/v2/D4D03AQGGBHEdUkz_DA/profile-displayphoto-crop_800_800/B4DZuDRnq6GgAI-/0/1767433995329?e=1775692800&v=beta&t=8aAHNpOrwKAL726SingWCHr6bHAmIzn-rk3QVMbMsB0', 'Igbani', 'Angus', 'WPCC/RE/', NULL),
	('46e9b6c8-991c-5c7b-8b2d-74597c54173e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Cyril Victor', '7063718185.0', NULL, '0115', '2026-04-08', false, '2026-04-08 07:24:14.266395', NULL, 'Victor', 'Cyril', 'WPCC/HQ/', NULL),
	('afce8e7b-e114-518b-a169-c2c1261554cd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Neriton Prefa Mirabel', '8169703054.0', NULL, '0132', '2026-04-08', false, '2026-04-08 07:27:32.215241', NULL, 'Prefa Mirabel', 'Neriton', 'WPCC/HQ/', NULL),
	('55c2775d-2e55-58a1-a6f5-2d036208cab3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Elizabeth Joseph Akidy', NULL, NULL, '0125', '2026-04-08', false, '2026-04-08 07:24:14.266395', NULL, 'Joseph Akidy', 'Elizabeth', 'WPCC/HQ/', NULL),
	('f8c18b92-e5e3-5b29-b7e8-9a7dbff338ae', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Idu Maudlyn', '8060936660.0', NULL, '0123', '2026-04-08', false, '2026-04-08 07:24:14.266395', NULL, 'Maudlyn', 'Idu', 'WPCC/HQ/', NULL),
	('b8296b18-2881-56b0-8f8b-5da2a2c53e03', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Juliet Akioya', '8033692959.0', NULL, '0124', '2026-04-08', false, '2026-04-08 07:27:32.215241', NULL, 'Akioya', 'Juliet', 'WPCC/HQ/', NULL),
	('b4caed66-5496-53ce-b229-34c82e9a235b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'Oyewole Kehinde', '8056395419.0', NULL, '0093', '2026-04-08', false, '2026-04-08 07:30:40.200729', NULL, 'Kehinde', 'Oyewole', 'WPCC/HQ/', NULL),
	('5c0fd8c2-6c72-5e5e-b2bc-782559bf1e7a', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'Sarah Francis Minimah', '7068519221.0', NULL, '0136', '2026-04-08', false, '2026-04-08 07:30:40.200729', NULL, 'Francis Minimah', 'Sarah', 'WPCC/HQ/', NULL),
	('24f737eb-9001-46a9-89a8-11f8a75b43d7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Test Administrator', NULL, NULL, 'RE-00405', '2026-03-04', false, '2026-03-04 11:13:06.294564', 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/24f737eb-9001-46a9-89a8-11f8a75b43d7.jpg', NULL, NULL, 'WPCC/HQ/', NULL),
	('2a1ea96f-02e1-598d-a7e1-0d023a520ef6', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Faith Presley', '8167704009.0', NULL, '0090', '2023-04-01', false, '2026-04-07 21:28:20.097017', NULL, 'Presley', 'Faith', 'WPCC/HQ/', NULL),
	('11641715-8db0-50bb-b41f-2fc14aa7122d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'a4bb9e51-b105-43a9-801c-14dd4ad60c1d', 'Chidinma Diribe', '8036208727.0', NULL, '0019', '2026-04-07', false, '2026-04-07 21:32:08.498107', NULL, 'Diribe', 'Chidinma', 'WPCC/HQ/', NULL),
	('6c186f2c-94b9-5c34-bf35-9de4a83a4efd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'Emi Elfrida Godwin', '7038613565.0', NULL, '0013', '2024-10-01', false, '2026-04-07 21:28:20.097017', NULL, 'Elfrida Godwin', 'Emi', 'WPCC/HQ/', NULL),
	('90556612-dd95-54aa-b469-a9aeff809687', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'Kassin Hauwa Esther', '8034580273.0', NULL, '0052', '2025-10-01', false, '2026-04-07 21:28:20.097017', NULL, 'Hauwa Esther', 'Kassin', 'WPCC/HQ/', NULL),
	('4aed5d09-24fc-57e2-b763-1fb1d87e4cc3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Christain Eze', '9067460198.0', NULL, '0107', '2017-01-01', false, '2026-04-07 21:28:20.097017', NULL, 'Eze', 'Christain', 'WPCC/HQ/', NULL),
	('33e87363-203d-55b1-a607-8dca27a46eed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Afoloyan Helen', '8067138589.0', NULL, '0040', '1905-07-15', false, '2026-04-07 21:28:20.097017', NULL, 'Helen', 'Afoloyan', 'WPCC/HQ/', NULL),
	('182f6be1-65f3-5289-bde1-7833f1f17a71', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'Prince Edibamode', '8077957414.0', NULL, '0021', '2026-04-07', false, '2026-04-07 21:30:57.681195', NULL, 'Edibamode', 'Prince', 'WPCC/HQ/', NULL),
	('836e1d11-b1fd-5c86-8f52-e25973dc0712', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Victor Patience', '7065457935.0', NULL, '0049', '2017-05-01', false, '2026-04-07 21:30:57.681195', NULL, 'Patience', 'Victor', 'WPCC/HQ/', NULL),
	('a70f0fe0-2a30-5868-a046-00ebc1843f64', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Grace Sukuye', '8117199258.0', NULL, '0041', '1905-07-04', false, '2026-04-07 21:30:57.681195', NULL, 'Sukuye', 'Grace', 'WPCC/HQ/', NULL),
	('85ea5802-7ba1-5ff9-a8ab-52f8f965c84d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Ogerejeko Pamela', '8109089870.0', NULL, '0055', '2026-04-07', false, '2026-04-07 21:30:57.681195', NULL, 'Pamela', 'Ogerejeko', 'WPCC/HQ/', NULL),
	('1f47e3e6-55d8-5012-bccb-109553f8a2a0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Chinedu Oge Mary', '8033090319.0', NULL, '0095', '2026-04-07', false, '2026-04-07 21:30:57.681195', NULL, 'Oge Mary', 'Chinedu', 'WPCC/HQ/', NULL),
	('cdd47eec-8545-5582-9658-6cf0d40ae0e1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Alalibo Ibifubara Favour Deinsobote', '9121955467.0', NULL, '0067-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Ibifubara Favour Deinsobote', 'Alalibo', 'WPCC/HQ/', NULL),
	('7bc7082a-e83e-5127-9db1-be3962f53d9e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'Godstime Horsefall', '9131913979.0', NULL, '0086', '2026-04-07', false, '2026-04-07 21:32:08.498107', NULL, 'Horsefall', 'Godstime', 'WPCC/HQ/', NULL),
	('57bfc01d-8315-5cbe-9bf0-5d9fa4a34a5c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '49831aa5-ffbe-44f3-bc8f-6e639553474e', 'Peggy Efe Enaibre', '8023255460.0', NULL, '0006', '2026-04-07', false, '2026-04-07 21:32:08.498107', NULL, 'Efe Enaibre', 'Peggy', 'WPCC/HQ/', NULL),
	('9ee0ff4f-80fc-5e45-aa1f-056c0b346008', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Igbani Bilha Claude', '9033846542.0', NULL, '0020', '2026-04-07', false, '2026-04-07 21:33:10.567939', NULL, 'Bilha Claude', 'Igbani', 'WPCC/HQ/', NULL),
	('f7894dcb-2794-5a0d-9e0b-0f640efbf80c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '46c85893-3953-4337-84f9-edb1806b0669', 'Victor Chilvers', '8064810667.0', NULL, '0009', '2026-04-07', false, '2026-04-07 21:32:08.498107', NULL, 'Chilvers', 'Victor', 'WPCC/HQ/', NULL),
	('84f9c52e-1a16-57ea-8d62-7589c3e875cf', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'Claude Ibiye Igbani', '8037092501.0', NULL, '0068-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Ibiye Igbani', 'Claude', 'WPCC/HQ/', NULL),
	('0ef80e26-1f47-52a8-882e-660f3036ccc2', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2ddfe8b3-72c7-49d6-9450-588ce6d72ed3', 'Iyingi Divine Sukuye', '8038900266.0', NULL, '0010', '2026-04-07', false, '2026-04-07 21:32:39.050584', NULL, 'Divine Sukuye', 'Iyingi', 'WPCC/HQ/', NULL),
	('344aa4cd-5f9c-5288-819b-3b9ae2095af7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Oluwapelumi Ibitoye', '9093750964.0', NULL, '0012', '2026-04-07', false, '2026-04-07 21:32:39.050584', NULL, 'Ibitoye', 'Oluwapelumi', 'WPCC/HQ/', NULL),
	('a65cf3a7-40b1-5bd1-92cc-a0f4db703ab6', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Jeremiah Sharon', '8061620534.0', NULL, '0049-1', '2026-04-07', false, '2026-04-07 21:40:51.818135', NULL, 'Sharon', 'Jeremiah', 'WPCC/HQ/', NULL),
	('2b98f83f-35a0-5dcc-b86f-7fa5ebe303f4', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Ebi Uchenna K', '8083119504.0', NULL, '0015', '2026-04-07', false, '2026-04-07 21:32:39.050584', NULL, 'Uchenna K', 'Ebi', 'WPCC/HQ/', NULL),
	('7c3edc10-5798-5c10-86fa-a5205b724472', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', '0wabia Emmanuella Adaeze', '9066077623.0', NULL, '0069-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Emmanuella Adaeze', '0wabia', 'WPCC/HQ/', NULL),
	('d510924a-5e33-5f69-be69-0982dfe7f0e7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'Sunny Johnny', '7038804592.0', NULL, '0016', '2025-01-01', false, '2026-04-08 09:55:26.899423', NULL, 'Johnny', 'Sunny', 'WPCC/HQ/', NULL),
	('46d0856e-9f34-56a5-b954-6246d3647b4c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Ogunsuware Tamaramiebi Glory', '9022200981.0', NULL, '0070', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Tamaramiebi Glory', 'Ogunsuware', 'WPCC/HQ/', NULL),
	('0a87aff0-1493-580f-a263-03bc8a28fdac', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'JoshuaTamaraebikemiene Sophia', '9066521218.0', NULL, '0071', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Sophia', 'JoshuaTamaraebikemiene', 'WPCC/HQ/', NULL),
	('620ec5dd-b6f7-57a2-b08e-dbd81ece9ce1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Emmanuel Chukwueke', '7012110617.0', NULL, '0065-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Chukwueke', 'Emmanuel', 'WPCC/HQ/', NULL),
	('6ca918ed-e773-52ae-9f82-6685d81f73bf', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'd94730d7-4ee6-4e40-83c4-573ffe0c6e1d', 'Idowu Mufato', '8064341666', NULL, '0078', '2026-04-08', false, '2026-04-08 07:16:59.114499', NULL, 'Mufato', 'Idowu', 'WPCC/HQ/', NULL),
	('73014d1d-2851-54b1-a706-f1ee6868d407', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Gift Charles', '8060152337.0', NULL, '0063-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Charles', 'Gift', 'WPCC/HQ/', NULL),
	('16fa675d-23c2-5e11-9fb2-33e0f5eccfdc', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Balogun Ayomide', '8142774114.0', NULL, '0064', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Ayomide', 'Balogun', 'WPCC/HQ/', NULL),
	('c5ae808b-48b6-5575-b032-4983f9d1751c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'Joshua Lawrence', '7037716689.0', NULL, '0065-2', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Lawrence', 'Joshua', 'WPCC/HQ/', NULL),
	('7edafbb8-d2b2-584e-be78-f1f5a17e2a22', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '777796f6-7ea3-4ceb-a95b-eafcf573bc9f', 'Bright Bethel Pepple', '8164976820.0', NULL, '0066-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Bethel Pepple', 'Bright', 'WPCC/HQ/', NULL),
	('12dc39be-d1f0-5150-9162-8c5cd15a4f83', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Bright Chidera Osayi', '9057545074.0', NULL, '0111', '2026-04-08', false, '2026-04-08 07:21:47.544856', NULL, 'Chidera Osayi', 'Bright', 'WPCC/HQ/', NULL),
	('b0a90f0d-da25-5533-9e54-b61ca723e8e0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Ebitari Life Osaronwolu', '8037661640.0', NULL, '0018', '2026-04-07', false, '2026-04-07 21:33:10.567939', NULL, 'Life Osaronwolu', 'Ebitari', 'WPCC/HQ/', NULL),
	('4a9b8455-2e2c-5310-9ff0-d91fc1aabb05', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Joseph Akidy Israel', '9168051179.0', NULL, '0112', '2026-04-08', false, '2026-04-08 07:21:47.544856', NULL, 'Akidy Israel', 'Joseph', 'WPCC/HQ/', NULL),
	('33689fc4-d9fb-5905-b41d-4aa3d6f28813', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Sukuye Dumo Joshua', '9039504111.0', NULL, '0038', '2026-04-07', false, '2026-04-07 21:33:10.567939', NULL, 'Dumo Joshua', 'Sukuye', 'WPCC/HQ/', NULL),
	('41a8efe7-56d9-52da-9e48-48735d9d4fab', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Idu Daniel', '7071064522.0', NULL, '0089', '2026-04-08', false, '2026-04-08 07:18:17.835044', NULL, 'Daniel', 'Idu', 'WPCC/HQ/', NULL),
	('e1c3c4c8-b903-5f1c-9149-f171031f4252', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'Anuliyo Juliet Ekwutsi', '8032627844.0', NULL, '0091', '2019-07-04', false, '2026-04-08 07:20:17.099342', NULL, 'Juliet Ekwutsi', 'Anuliyo', 'WPCC/HQ/', NULL),
	('0b153e44-0f42-5195-8754-2737ca5dc94b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Chinwendu Oge Rose Mary', '8033090319.0', NULL, '0095-1', '2026-04-08', false, '2026-04-08 07:20:17.099342', NULL, 'Oge Rose Mary', 'Chinwendu', 'WPCC/HQ/', NULL),
	('0affa6e3-51cd-5955-b7ac-720eb6a8bd99', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Njujima Rolins Ayomide', '9028694922.0', NULL, '0096', '2021-10-04', false, '2026-04-08 07:20:17.099342', NULL, 'Rolins Ayomide', 'Njujima', 'WPCC/HQ/', NULL),
	('87cbe629-a4c0-5935-bee6-32f17be82cea', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e14a403b-9739-45ef-8a24-b90866749318', 'Temitope Ologun Benstowe', '8033519259.0', NULL, '0097', '2014-04-01', false, '2026-04-08 07:20:17.099342', NULL, 'Ologun Benstowe', 'Temitope', 'WPCC/HQ/', NULL),
	('fbd5d811-c3e5-59a1-b9a4-06bfb166dd7b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Idara Lawrence Tom Bob Manuel', '8025971777.0', NULL, '0126', '2026-04-08', false, '2026-04-08 07:27:32.215241', NULL, 'Lawrence Tom Bob Manuel', 'Idara', 'WPCC/HQ/', NULL),
	('2fe4c83f-97e0-5a73-a54d-79e056c795af', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'Joe Benson Oka', '8027478494.0', NULL, '0101', '2026-04-08', false, '2026-04-08 07:20:17.099342', NULL, 'Benson Oka', 'Joe', 'WPCC/HQ/', NULL),
	('15458965-71f0-5401-bcbb-be5916bcf63d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'Uloma I Iheanmeli', '7067078118.0', NULL, '0105', '2026-04-08', false, '2026-04-08 07:21:47.544856', NULL, 'I Iheanmeli', 'Uloma', 'WPCC/HQ/', NULL),
	('7078799d-6cde-449d-b202-2f09f1e28e33', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'christian eze TT', '3456776543234', NULL, NULL, '2026-03-06', false, '2026-03-06 02:09:56.953325', NULL, 'eze', 'christian', 'WPCC/RE/', NULL),
	('5a1d5b85-b39e-440e-a5f0-656b8097a165', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '46c85893-3953-4337-84f9-edb1806b0669', 'Adeshina Gentry TT', '+2348098765432', 'Global senior pastor', 'RE-00001', '2026-03-01', true, '2026-03-01 18:34:29.055484', 'https://pbs.twimg.com/profile_images/1286604948780781569/w08pirm2_400x400.jpg', 'Adeshina  ', 'Gentry', 'WPCC/RE/', NULL),
	('d4bb3016-28da-5bda-8bf8-d5f3b49f5870', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Daniella Neriton Prefa Zikere', '9131601607.0', NULL, '0128', '2026-04-08', false, '2026-04-08 07:27:32.215241', NULL, 'Neriton Prefa Zikere', 'Daniella', 'WPCC/HQ/', NULL),
	('049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Glory Okon Johnny', '9046606929.0', NULL, '0106', '2020-02-16', false, '2026-04-08 07:21:47.544856', NULL, 'Okon Johnny', 'Glory', 'WPCC/HQ/', NULL),
	('f82d951d-a444-4f4d-b63b-d342582afdcd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Igbani angus Claude', '9132652134', NULL, '0104', '2026-04-08', false, '2026-04-08 08:11:23.082382', NULL, 'angus Claude', 'Igbani', 'WPCC/HQ/', NULL);


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."announcements" ("id", "title", "content", "scope", "branch_id", "department_id", "created_by", "created_at", "mediaurl", "hasmedia") VALUES
	('cafa5261-4a11-4a26-9a28-0d2917ee77ad', 'New Month Divine Acceleration', 'May this new month bring divine acceleration to every member of the WPCC family. Let''s expect rapid progress in every area of life.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('ec5f400a-438a-47b1-8ea8-439a86ed4f11', 'Mid-Week Bible Study', 'Join us this Wednesday at 7 PM for an enlightening Bible study session. Let''s grow together in the Word of God.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('a252ade2-2c26-4f8c-b68a-6fcbcfb815c3', 'Prayer Meeting', 'Our weekly prayer meeting takes place every Friday at 6 AM. Come ready to intercede and receive divine guidance.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('e0e5a88c-1e85-409f-920d-583ce16563a8', 'Fellowship Event Next Sunday', 'Next Sunday, after service, we will have a fellowship event for all members. It will be a time of connection and fun. Don''t miss out!', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('54e8d7d3-b78e-4a3a-804d-7508086dbf2e', 'New Members Orientation', 'We are excited to welcome our new members! Join us for an orientation session next Sunday at 10 AM in the Fellowship Hall.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('76d686e6-5af4-4347-8870-1d464fedd8cf', 'Volunteer Opportunities', 'Looking for ways to serve? The Church is in need of volunteers for our upcoming event. Please sign up at the welcome desk.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('937bad40-5c35-4a28-a784-31102f395d2c', 'Sunday Service Reminder', 'Reminder: Join us for Sunday service at 9 AM. Come expecting a powerful Word and time of worship.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('ccb0aa3c-66a2-4703-9bb2-da845700c1d1', 'Staff Training Day', 'Attention all staff: There will be a mandatory training session on Monday at 10 AM in the conference room. Please be punctual.', 'department', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('a629e2eb-42a8-4848-92ae-4888e8333acc', 'Bible School Enrollment', 'Enrollment for the upcoming Bible School session is now open. Classes will begin next month. Please visit the office to register.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('6b6752d3-e0da-4e10-acf5-c3b626cb83a1', 'Special Healing Service', 'We will hold a special healing service this Friday at 7 PM. Come expectant for miracles and breakthroughs.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('bb137a97-4087-422f-894a-09f51a1f07d0', 'Church Office Closed', 'Please note that the church office will be closed this Monday in observance of the public holiday.', 'branch', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('c6a92caf-530f-4709-aa94-ccdc4be55069', 'New Prayer Request Form', 'A new prayer request form has been made available on our website. Feel free to submit your prayer requests online.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('8a833fef-370a-4821-841e-e1ee7abb6575', 'Community Outreach Program', 'Our community outreach program is scheduled for next Saturday at 10 AM. Volunteers are welcome to join as we reach out to the less fortunate.', 'branch', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('70986a1a-edf4-4547-b0e4-76ff637fd60d', 'Baptism Class', 'The next baptism class will be held next Sunday after service. If you would like to be baptized, please sign up at the welcome desk.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('fb926b33-8bc3-4e7f-ae99-568c0e08ba02', 'Church Clean-Up Day', 'We are organizing a clean-up day this coming Saturday. All volunteers are welcome to help keep our church facilities beautiful.', 'branch', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('ee17c485-52b4-4288-9841-3a407456d106', 'Monthly Newsletter', 'The monthly newsletter is now available online. Be sure to read it for important updates, upcoming events, and church news.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('c2336eba-b879-4f2a-b018-7ddeb2fd0d30', 'Christmas Eve Service', 'Save the date! Our Christmas Eve service will be held on December 24th at 6 PM. Bring your family and friends for a special celebration.', 'global', NULL, NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('6effd6e1-5726-4598-afad-ba540294c8f0', 'Men’s Fellowship Breakfast', 'Join us this Saturday at 8 AM for a fellowship breakfast. Let''s come together for fellowship and great food!', 'department', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('4302a990-8376-479a-a510-79d0a2f9300a', 'Charity Drive Update', 'Our charity drive continues this month. Please bring non-perishable food items to support those in need in our community.', 'branch', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', NULL, NULL, '2026-03-04 20:47:30.871354', NULL, NULL),
	('3398d00e-1113-4a87-98c3-385be19da373', 'Youth Ministry Meeting', 'The Youth Ministry will meet this Saturday at 3 PM for a special session on leadership development. All youth members are encouraged to attend.', 'department', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', 'dcea05e8-fc39-4851-935c-808643593c73', NULL, '2026-03-04 20:47:30.871354', NULL, NULL);


--
-- Data for Name: recurring_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."global_recurring_events" ("id", "title", "description", "recurrence_type", "day_of_week", "week_of_month", "day_of_month", "month", "start_time", "end_time", "featured_url", "is_active", "created_by", "created_at", "updated_at") VALUES
	('5701e7fc-98b5-4f4f-94c8-ac530c500771', 'Business service', 'Join us for a powerful and inspiring church service designed specifically for business owners! This special service will focus on spiritual growth, leadership, and success in the marketplace. As entrepreneurs, we often face unique challenges that require both faith and wisdom, and this service aims to provide a space where you can draw closer to God while gaining practical insights to thrive in your business journey.', 'weekly', 0, NULL, NULL, NULL, '07:30:00', '08:30:00', 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/669732598_18369709042204822_6004529508732304295_n.jpg?_nc_cat=106&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeHSK9iAjMD3UV1q_YouqBpBDcJqikBTmn8NwmqKQFOaf27KgHd_f5wlteF2ur7oQfOshAhLO8A9YmSVDptAUq77&_nc_ohc=2PGkvQk0VwkQ7kNvwH3J3be&_nc_oc=AdoMJOVURP4ujTO46-JbXPCXqnr8gADTbbi2gDqNeiIVUEuRgIXof9mcCWVzzfaCj8M&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=-vn06fCUB_PmYUJHA9w1Mg&_nc_ss=7b2a8&oh=00_Af3pbLu-rqDnUUN3Y9mvr_MdoET-MawK8EqVn0U4b-ss3g&oe=69F7A1C9', true, 'seed.sql', '2026-04-29 10:39:45.314153+00', '2026-04-29 10:39:45.314153+00'),
	('2171a298-e339-4d23-a4c4-57b6ab8dfa42', 'Family worship service', 'Join us for a special Family Worship Service designed to bring families together in faith, unity, and love. This event is an opportunity for every family member, from the youngest to the oldest, to come together and experience the power of worship in a welcoming and joyful atmosphere. Through heartfelt praise, powerful worship songs, and inspiring messages, we aim to strengthen the spiritual bond within families and encourage them in their Christian walk.', 'weekly', 0, NULL, NULL, NULL, '09:00:00', '11:30:00', 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/671218647_18370528150204822_2228041907418378845_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeEIZfqPEkGThjFb8EBZXy7tLjH8trbr1u8uMfy2tuvW74DPTvr63JgWKhLaGzDRNMj2qzF-omwtpMmEky4FGwWl&_nc_ohc=zTpOAKAagc4Q7kNvwFwvUnP&_nc_oc=AdqHNb_dp5S_bIcnUqYFXTS_PRQ5aNQR9yfawiDGT59uOlYMw9m0xJHa2_ofiGhnbX0&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=bVpG_95ASLmAnppo4Qp1XA&_nc_ss=7a2a8&oh=00_Af7kTmbgeKXV-BwEUbx7t4wtHvdp_DLShWfzSS7tJMGnXg&oe=69F9CC81', true, 'seed.sql', '2026-05-01 02:15:39+00', '2026-05-01 02:15:39+00'),
	('12fda143-bf68-4a4a-b9b1-3c6b3d0162de', 'Miracle communion service', 'Experience divine intervention and spiritual renewal at our Miracle Communion Service this midweek. This special service is designed to bring God''s miraculous power into your life as we partake in the sacred act of communion, believing for healing, breakthrough, and restoration.

Join us for an evening of powerful prayer, anointed worship, and a timely message that will ignite your faith and encourage you to step into the fullness of God''s promises. During this service, we will partake in communion, symbolizing our covenant with Christ, and aligning ourselves with His power to heal, deliver, and transform lives.', 'weekly', 5, NULL, NULL, NULL, '05:30:00', '07:30:00', 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/659626174_18368307715204822_2743028741766509114_n.jpg?_nc_cat=109&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeEA4s_j6w3JSlMTlKAbugmc67dmAXbcGsPrt2YBdtwawyXxGxL96OGomC0K4cF13xdGsuDbOfJ80dlY0nFMtRsw&_nc_ohc=MTgLjbzSqUcQ7kNvwFL9FdK&_nc_oc=AdoomAU5dZZ9CRHSt84Ockt4ZFCDloNR9Y133iyHHk3jDTbzWRWREBZDHtc7KgC3n1o&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=irtZw8-zgHArYBFdQT0dKg&_nc_ss=7a2a8&oh=00_Af42oQ2E6rDsCLNw9FB5DaP702mNeIkeRdux3JOGVOzUBA&oe=69F9E21F', true, 'seed.sql', '2026-05-01 02:33:26+00', '2026-05-01 02:33:26+00');


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

WITH seed_events(id, title, description, event_date, scope, branch_id, created_by, created_at, isactive, endtime, featured_url, location, latitude, longitude, recurring_event_id) AS (
	VALUES
	('4a353828-3229-49c4-9797-13bb7c84e311'::uuid, 'Choir Practice Session'::text, 'Choir rehearsal and song practice.'::text, '2026-05-02 03:00:00'::timestamptz, 'global'::text, NULL::uuid, 'Seed'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-05-02 19:00:00.105806+00'::timestamptz, NULL::text, 'Main Auditorium'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('a265934a-79e3-4f41-8742-755b00b669a8'::uuid, 'Leadership Prayer & Planning'::text, 'Ongoing session for leaders and coordinators.'::text, '2026-04-29 10:20:50'::timestamptz, 'global'::text, NULL::uuid, 'Seed'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-04-29 11:50:56.105806+00'::timestamptz, NULL::text, 'Conference Room'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('dfaefe4a-438a-4516-b213-d1dcd58b4fb7'::uuid, 'Youth Fellowship Meeting'::text, 'Youth fellowship and worship.'::text, '2026-05-12 17:30:00'::timestamptz, 'global'::text, NULL::uuid, 'Seed'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-05-12 19:00:00+00'::timestamptz, 'https://scontent.fiba2-2.fna.fbcdn.net/v/t51.82787-15/659068846_18368740411204822_7513799047245127223_n.jpg?_nc_cat=104&ccb=1-7&_nc_sid=13d280&_nc_ohc=Qi6AnjerMJAQ7kNvwEfMakI&_nc_oc=Adougd0GRo7kCAccCz3BPgV3t66tJyfFxKa_hd_H9re37U7sUhMasaRzlUMrcg53ZJ0&_nc_zt=23&_nc_ht=scontent.fiba2-2.fna&_nc_gid=umQlC4yKfFhNnBcSWv3jAg&_nc_ss=7b289&oh=00_Af6pJAovS9ryZJUjtUpzCAfCLxHXU4p25Lnvjrm_ycDiNw&oe=69FB9D40'::text, 'Youth Hall'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('5fb87dc7-7e3e-4414-8e54-38dc7827369c'::uuid, 'Breakthrough Communion Service'::text, 'Covenant of exemption'::text, '2026-05-07 17:00:00'::timestamptz, 'branch'::text, '5a65519c-cf68-4977-9e44-fc3f206ec9fb'::uuid, ''::text, '2026-04-15 22:04:30.839'::timestamptz, true, '2026-05-14 17:30:00+00'::timestamptz, 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776287000713_scaled_656837334_18367733518204822_6430428026206091633_n.jpg'::text, NULL::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('7d26c101-dc52-492b-8531-3f2ead83f005'::uuid, 'Family Worship Service'::text, 'Kingdom harvest in glory'::text, '2026-05-03 09:00:00'::timestamptz, 'global'::text, 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53'::uuid, ''::text, '2026-04-15 22:02:59.507'::timestamptz, true, '2026-07-16 12:00:00+00'::timestamptz, 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776286901899_scaled_659626174_18368307715204822_2743028741766509114_n.jpg'::text, NULL::text, 4.807819449840962::double precision, 6.975654603585529::double precision, NULL::uuid),
	('abdfa7f6-d849-40c5-bfed-d6d254b8df2d'::uuid, 'Midweek Bible Study'::text, 'Ongoing Bible study and discussion.'::text, '2026-04-29 10:05:56.105806'::timestamptz, 'global'::text, NULL::uuid, 'Seed'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-04-29 11:20:56.105806+00'::timestamptz, NULL::text, 'Education Center'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('a2daea15-ad44-409a-8d7b-8f4bd9caa2ac'::uuid, 'Church Revival Service'::text, 'Evening revival service for all members.'::text, '2026-04-19 10:50:56.105806'::timestamptz, 'global'::text, NULL::uuid, 'Seed'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-04-19 12:50:56.105806+00'::timestamptz, NULL::text, 'Main Auditorium'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('a8e160f9-aad8-4c6e-aae3-2bd8fd95be22'::uuid, 'Business Service'::text, 'Sunday worship with praise and sermon.'::text, '2026-05-03 07:30:00'::timestamptz, 'global'::text, NULL::uuid, 'Seed'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-05-03 08:30:00+00'::timestamptz, 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/669732598_18369709042204822_6004529508732304295_n.jpg?_nc_cat=106&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeHSK9iAjMD3UV1q_YouqBpBDcJqikBTmn8NwmqKQFOaf27KgHd_f5wlteF2ur7oQfOshAhLO8A9YmSVDptAUq77&_nc_ohc=2PGkvQk0VwkQ7kNvwH3J3be&_nc_oc=AdoMJOVURP4ujTO46-JbXPCXqnr8gADTbbi2gDqNeiIVUEuRgIXof9mcCWVzzfaCj8M&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=-vn06fCUB_PmYUJHA9w1Mg&_nc_ss=7b2a8&oh=00_Af3pbLu-rqDnUUN3Y9mvr_MdoET-MawK8EqVn0U4b-ss3g&oe=69F7A1C9'::text, 'WPCC His Glory Expression'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('2bdad319-84ed-4bac-819b-0df3b3863ab3'::uuid, 'Business service'::text, 'Join us for a powerful and inspiring church service designed specifically for business owners! This special service will focus on spiritual growth, leadership, and success in the marketplace. As entrepreneurs, we often face unique challenges that require both faith and wisdom, and this service aims to provide a space where you can draw closer to God while gaining practical insights to thrive in your business journey.'::text, '2026-06-14 07:30:00'::timestamptz, 'global'::text, NULL::uuid, 'recurring_events_sync'::text, '2026-06-01 10:59:22.440392'::timestamptz, true, '2026-06-14 08:30:00+00'::timestamptz, 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/669732598_18369709042204822_6004529508732304295_n.jpg?_nc_cat=106&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeHSK9iAjMD3UV1q_YouqBpBDcJqikBTmn8NwmqKQFOaf27KgHd_f5wlteF2ur7oQfOshAhLO8A9YmSVDptAUq77&_nc_ohc=2PGkvQk0VwkQ7kNvwH3J3be&_nc_oc=AdoMJOVURP4ujTO46-JbXPCXqnr8gADTbbi2gDqNeiIVUEuRgIXof9mcCWVzzfaCj8M&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=-vn06fCUB_PmYUJHA9w1Mg&_nc_ss=7b2a8&oh=00_Af3pbLu-rqDnUUN3Y9mvr_MdoET-MawK8EqVn0U4b-ss3g&oe=69F7A1C9'::text, NULL::text, NULL::double precision, NULL::double precision, '5701e7fc-98b5-4f4f-94c8-ac530c500771'::uuid),
	('c282f662-1d0d-44e1-af42-948514692085'::uuid, 'Dream Team Workers Congress'::text, 'The Dream Team Workers Congress is a transformative event designed specifically for all church workers, volunteers, and leaders who serve in various ministries within the church. This congress is a powerful opportunity for personal growth, empowerment, and spiritual rejuvenation as we come together to build a stronger, more effective ministry team.

Throughout this gathering, we will engage in dynamic workshops, inspiring messages, and fellowship, all centered around equipping our workers to better serve in their respective roles. The congress will focus on leadership development, effective ministry strategies, teamwork, and a deeper understanding of the calling to serve in the kingdom of God.'::text, '2026-05-02 09:00:00'::timestamptz, 'global'::text, NULL::uuid, 'admin'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-05-02 11:00:00+00'::timestamptz, 'https://scontent.fabb1-3.fna.fbcdn.net/v/t51.82787-15/592532020_18352877707204822_229829812819282824_n.jpg?_nc_cat=104&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeE1O48iIM_4TcCvxgpoYeyMIv7NYnP1Qj8i_s1ic_VCP83JC0Rg3os5Ej7AByWjVKZMc_ACGSdbONI7eBBXPwZu&_nc_ohc=l1OeO8YtXHsQ7kNvwH7cO77&_nc_oc=AdpQG1QEP-mpJkO162fTprILVb2WJJh7iAawYyYM6UZmhXROSqny1v2uETbWT3aLcVs&_nc_zt=23&_nc_ht=scontent.fabb1-3.fna&_nc_gid=Cph1Ee5fkZ6LiYxafMz8Yw&_nc_ss=7a2a8&oh=00_Af4zvSumhgYEvxcgT9uF5YSQTFFcYUecLkzZghSOV-iLNw&oe=69F9D54F'::text, 'WPCC His Glory Expression'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('83418de7-e1e4-4ef8-8261-c4e598d71fcd'::uuid, 'Good Morning HolySpirit - May Edition'::text, 'Start your month with a fresh outpouring of the Holy Spirit at our Good Morning Holy Spirit Service. Held on the first day of every month, this special service is dedicated to welcoming God''s presence into our lives, setting the tone for the days ahead, and seeking His guidance, grace, and empowerment for the month to come.

Join us for an intimate time of worship, prayer, and prophetic declarations, as we invite the Holy Spirit to lead, inspire, and fill us with renewed strength and purpose. This service is designed to help you begin each month with a deep connection to God, grounding you in His Word and the power of His Spirit.'::text, '2026-05-01 06:15:00'::timestamptz, 'global'::text, NULL::uuid, 'admin'::text, '2026-04-29 10:50:56.105806'::timestamptz, true, '2026-05-01 08:00:00+00'::timestamptz, 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/598376136_18352877719204822_1171968326056638756_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeGatL6xDaH9JpzR4h5C762DQSdmuis6pZxBJ2a6KzqlnAitq0GSejQ5mJJkR3aN0sxbFwaf8ynZITMf-ltqtNW9&_nc_ohc=0Z78-b2SK20Q7kNvwHMf3wc&_nc_oc=Adrs36fuTIqeCMBCbs8WD-hxi5JNiUI9wWX0vrVYgOJcxW2inyiieLiJwnZf1cYiyPo&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=YOb3D4h4MkpEtJPAjdRaZQ&_nc_ss=7a2a8&oh=00_Af5UeX2ZsiGbqsJIvm51IN5jhIQGXmiNms8IcK_68dn1ug&oe=69F9FEA7'::text, 'All Expressions'::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid),
	('84391a63-8a79-4ed9-9b10-47d0adf4eed1'::uuid, 'Family worship service'::text, 'Join us for a special Family Worship Service designed to bring families together in faith, unity, and love. This event is an opportunity for every family member, from the youngest to the oldest, to come together and experience the power of worship in a welcoming and joyful atmosphere. Through heartfelt praise, powerful worship songs, and inspiring messages, we aim to strengthen the spiritual bond within families and encourage them in their Christian walk.'::text, '2026-06-14 09:00:00'::timestamptz, 'global'::text, NULL::uuid, 'recurring_events_sync'::text, '2026-06-01 10:59:22.440392'::timestamptz, true, '2026-06-14 10:30:00+00'::timestamptz, 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/671218647_18370528150204822_2228041907418378845_n.jpg?_nc_cat=100&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeEIZfqPEkGThjFb8EBZXy7tLjH8trbr1u8uMfy2tuvW74DPTvr63JgWKhLaGzDRNMj2qzF-omwtpMmEky4FGwWl&_nc_ohc=zTpOAKAagc4Q7kNvwFwvUnP&_nc_oc=AdqHNb_dp5S_bIcnUqYFXTS_PRQ5aNQR9yfawiDGT59uOlYMw9m0xJHa2_ofiGhnbX0&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=bVpG_95ASLmAnppo4Qp1XA&_nc_ss=7a2a8&oh=00_Af7kTmbgeKXV-BwEUbx7t4wtHvdp_DLShWfzSS7tJMGnXg&oe=69F9CC81'::text, NULL::text, NULL::double precision, NULL::double precision, '2171a298-e339-4d23-a4c4-57b6ab8dfa42'::uuid),
	('14f5c764-402f-4d06-9f2c-942b37d8c865'::uuid, 'Miracle communion service'::text, 'Experience divine intervention and spiritual renewal at our Miracle Communion Service this midweek. This special service is designed to bring God''s miraculous power into your life as we partake in the sacred act of communion, believing for healing, breakthrough, and restoration.

Join us for an evening of powerful prayer, anointed worship, and a timely message that will ignite your faith and encourage you to step into the fullness of God''s promises. During this service, we will partake in communion, symbolizing our covenant with Christ, and aligning ourselves with His power to heal, deliver, and transform lives.'::text, '2026-06-12 05:30:00'::timestamptz, 'global'::text, NULL::uuid, 'recurring_events_sync'::text, '2026-06-01 10:59:22.440392'::timestamptz, true, '2026-06-12 06:30:00+00'::timestamptz, 'https://scontent.fabb1-2.fna.fbcdn.net/v/t51.82787-15/659626174_18368307715204822_2743028741766509114_n.jpg?_nc_cat=109&ccb=1-7&_nc_sid=13d280&_nc_eui2=AeEA4s_j6w3JSlMTlKAbugmc67dmAXbcGsPrt2YBdtwawyXxGxL96OGomC0K4cF13xdGsuDbOfJ80dlY0nFMtRsw&_nc_ohc=MTgLjbzSqUcQ7kNvwFL9FdK&_nc_oc=AdoomAU5dZZ9CRHSt84Ockt4ZFCDloNR9Y133iyHHk3jDTbzWRWREBZDHtc7KgC3n1o&_nc_zt=23&_nc_ht=scontent.fabb1-2.fna&_nc_gid=irtZw8-zgHArYBFdQT0dKg&_nc_ss=7a2a8&oh=00_Af42oQ2E6rDsCLNw9FB5DaP702mNeIkeRdux3JOGVOzUBA&oe=69F9E21F'::text, NULL::text, NULL::double precision, NULL::double precision, '12fda143-bf68-4a4a-b9b1-3c6b3d0162de'::uuid)
)
INSERT INTO "public"."global_events" ("id", "title", "description", "event_start_at", "event_end_at", "featured_url", "location", "latitude", "longitude", "is_active", "created_by", "created_at", "updated_at", "source_recurring_event_id", "source_recurring_scope")
SELECT
	id,
	title,
	description,
	event_date,
	endtime,
	featured_url,
	location,
	latitude,
	longitude,
	isactive,
	COALESCE(NULLIF(created_by, ''), 'seed.sql'),
	created_at,
	created_at,
	recurring_event_id,
	CASE WHEN recurring_event_id IS NULL THEN NULL ELSE 'global' END
FROM seed_events
WHERE scope = 'global';

WITH seed_events(id, title, description, event_date, scope, branch_id, created_by, created_at, isactive, endtime, featured_url, location, latitude, longitude, recurring_event_id) AS (
	VALUES
	('5fb87dc7-7e3e-4414-8e54-38dc7827369c'::uuid, 'Breakthrough Communion Service'::text, 'Covenant of exemption'::text, '2026-05-07 17:00:00'::timestamptz, 'branch'::text, '5a65519c-cf68-4977-9e44-fc3f206ec9fb'::uuid, ''::text, '2026-04-15 22:04:30.839'::timestamptz, true, '2026-05-14 17:30:00+00'::timestamptz, 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776287000713_scaled_656837334_18367733518204822_6430428026206091633_n.jpg'::text, NULL::text, 4.80850070633439::double precision, 6.975305513766778::double precision, NULL::uuid)
)
INSERT INTO "public"."branch_events" ("id", "title", "description", "branch_id", "event_start_at", "event_end_at", "featured_url", "location", "latitude", "longitude", "is_active", "created_by", "created_at", "updated_at", "source_recurring_event_id", "source_recurring_scope")
SELECT
	id,
	title,
	description,
	branch_id,
	event_date,
	endtime,
	featured_url,
	location,
	latitude,
	longitude,
	isactive,
	COALESCE(NULLIF(created_by, ''), 'seed.sql'),
	created_at,
	created_at,
	recurring_event_id,
	CASE WHEN recurring_event_id IS NULL THEN NULL ELSE 'branch' END
FROM seed_events;


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."attendance" ("id", "user_id", "event_id", "status", "latitude", "longitude", "created_at", "branch_id", "department_id", "fullname", "confirmedby", "confirmedby_name", "clockout", "closedlat", "closedlong") VALUES
	('47be5411-1f93-4d1a-b485-9619848af15c', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'present', 4.808309, 6.97582, '2026-04-30 13:15:57.569291', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'Igbani Angus Claude', NULL, NULL, NULL, NULL, NULL),
	('414ae5a3-c874-4493-a5b0-27b938b83819', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '7d26c101-dc52-492b-8531-3f2ead83f005', 'present', 4.808309, 6.97582, '2026-04-30 23:09:17.605772', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Igbani angus Claude', NULL, NULL, NULL, NULL, NULL),
	('29939b34-306d-4344-95ef-a30487dfc1a9', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '83418de7-e1e4-4ef8-8261-c4e598d71fcd', 'present', 4.808480036574983, 6.975222042024931, '2026-05-01 05:21:48.19171', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Igbani angus Claude', NULL, NULL, NULL, NULL, NULL),
	('1e072863-5347-4e56-9098-6faff2484c27', 'f82d951d-a444-4f4d-b63b-d342582afdcd', 'c282f662-1d0d-44e1-af42-948514692085', 'present', 4.808558350298506, 6.975190888833637, '2026-05-02 08:11:18.953236', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Igbani angus Claude', NULL, NULL, NULL, NULL, NULL),
	('82032de7-a6bb-4a0f-af3d-bc338e89dcfb', '049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', 'c282f662-1d0d-44e1-af42-948514692085', 'present', 4.808438823858788, 6.975174040973107, '2026-05-02 09:10:50.450167', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Glory Okon Johnny', NULL, NULL, NULL, NULL, NULL),
	('02d3b1f8-cd18-4987-afb2-6c4c73264160', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '4a353828-3229-49c4-9797-13bb7c84e311', 'present', 4.808492095631881, 6.975198449315054, '2026-05-02 10:32:04.947059', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'Igbani angus Claude', NULL, NULL, NULL, NULL, NULL);


--
-- Data for Name: attendance_audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."attendance_audit_logs" ("id", "user_id", "event_id", "action", "occurred_at", "distance_m", "latitude", "longitude", "user_full_name", "request_ip", "user_agent", "raw_payload") VALUES
	('d9dbab44-fd7d-4616-87a6-cf25e50f4756', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_in', '2026-04-30 09:25:14.440027+00', NULL, NULL, NULL, 'Igbani Angus Claude', '102.90.99.81', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.807991403031859, "longitude": 6.975681747377445}, "server_decided_action": "clock_in"}'),
	('fc0dca99-ddd0-4309-87ad-cb56b3cae7c7', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 09:26:00.232713+00', NULL, NULL, NULL, 'Igbani Angus Claude', '102.90.99.81', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.807987, "longitude": 6.966795}, "server_decided_action": "clock_out"}'),
	('165ff42b-e02b-4823-9e98-02f2a7dc0ff5', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_in', '2026-04-30 09:33:44.633273+00', NULL, NULL, NULL, 'Igbani Angus Claude', '102.90.99.81', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.7731, "longitude": 7.0085}, "server_decided_action": "clock_in"}'),
	('20911d48-2e11-43ed-a065-3440fb7d5e01', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'invalid_location', '2026-04-30 10:47:57.638728+00', NULL, NULL, NULL, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "location_required", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.80796862713119, "longitude": 6.975668944174996}, "server_decided_action": "invalid_location"}'),
	('6efb0a25-49df-4e5c-a98c-56487f0befd4', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'invalid_location', '2026-04-30 10:48:05.385434+00', NULL, NULL, NULL, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "location_required", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.807970984454079, "longitude": 6.975670317157535}, "server_decided_action": "invalid_location"}'),
	('340cbcdc-e286-42cd-ac72-d2f4adc83588', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'invalid_location', '2026-04-30 11:17:58.501747+00', NULL, NULL, NULL, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"error": "location_required", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.7731, "longitude": 7.0085}, "server_decided_action": "invalid_location"}'),
	('50786812-c00a-4833-9886-c97f63a3857e', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_in', '2026-04-30 11:22:53.505377+00', NULL, 4.807987, 6.966795, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.807987, "longitude": 6.966795}, "attendance_written": true, "server_decided_action": "clock_in"}'),
	('046db520-be87-46d9-8f58-d1e6c181be5c', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 11:23:45.235171+00', NULL, 4.807987, 6.966795, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.807987, "longitude": 6.966795}, "server_decided_action": "clock_out"}'),
	('afc13cf4-f53d-436b-8b7f-7cf28d3bff00', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 11:32:24.189619+00', NULL, 4.808010869736807, 6.975692849966904, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.808010869736807, "longitude": 6.975692849966904}, "server_decided_action": "clock_out"}'),
	('20062d19-ab7f-4f9e-9619-fe87cf3c7dc6', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 11:32:33.912388+00', NULL, 4.808010869721382, 6.975692849940071, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.808010869721382, "longitude": 6.975692849940071}, "server_decided_action": "clock_out"}'),
	('1435b04b-c8cd-4365-b7cc-39b38256fdaa', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 11:32:44.019745+00', NULL, 4.808014181323812, 6.975694714308919, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.808014181323812, "longitude": 6.975694714308919}, "server_decided_action": "clock_out"}'),
	('2fe79f31-fdc5-46ce-b251-74a804f01b20', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 11:33:19.718909+00', NULL, 4.80801427154679, 6.975694405690597, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.80801427154679, "longitude": 6.975694405690597}, "server_decided_action": "clock_out"}'),
	('4e69046e-7bab-42d3-a43a-98c20fc5e254', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 11:33:29.177242+00', NULL, 4.808014938118812, 6.975695360014392, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "user_location": {"latitude": 4.808014938118812, "longitude": 6.975695360014392}, "server_decided_action": "clock_out"}'),
	('9f7ccd74-b941-4abc-8e92-c51bc13710cc', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 12:01:04.648419+00', 18.07624160083872, 4.807980174649265, 6.97567907087115, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "attendance_clock_out_failed", "details": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "distance_m": 18.07624160083872, "user_location": {"latitude": 4.807980174649265, "longitude": 6.97567907087115}, "server_decided_action": "clock_out"}'),
	('6852149a-8589-4d48-a0ae-750442463d50', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'invalid_location', '2026-04-30 12:31:18.937933+00', 981.8533310950286, 4.807987, 6.966795, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"error": "outside_geofence", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 4.807987, "longitude": 6.966795}}'),
	('279d193f-19b6-4ea0-877c-60c2e7fbf6fe', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_in', '2026-04-30 12:35:31.627677+00', 16.86674599937438, 4.807970001184003, 6.975673189891417, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 4.807970001184003, "longitude": 6.975673189891417}}'),
	('9efd2379-16d1-4fd2-830f-4695e1c2aec7', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 12:38:15.996556+00', 77.79410915833358, 4.808508, 6.975779, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"error": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 4.808508, "longitude": 6.975779}}'),
	('df4cb1cb-26a9-484b-89e7-8ac017b6500b', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'invalid_location', '2026-04-30 12:45:59.375495+00', 436621.6194775036, 6.4474, 3.3903, 'Igbani Angus Claude', '102.88.115.138', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"error": "outside_geofence", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 6.4474, "longitude": 3.3903}}'),
	('57f68077-b555-487d-bf7a-b70a01f2c713', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_in', '2026-04-30 13:15:57.889878+00', 57.43765766218322, 4.808309, 6.97582, 'Igbani Angus Claude', '102.93.11.50', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 4.808309, "longitude": 6.97582}}'),
	('fde3bef8-72e5-4130-951f-f8ce5906d2ed', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 15:59:11.529316+00', 17.905877506265067, 4.807978442487793, 6.975680237041733, 'Igbani Angus Claude', '102.93.11.50', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 4.807978442487793, "longitude": 6.975680237041733}}'),
	('c144d567-f155-4f7e-8e52-7cabe6d00be7', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-04-30 16:37:29.789926+00', 86.9747127737817, 4.808485550076112, 6.975243131497251, 'Igbani Angus Claude', '102.93.11.50', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 4.808485550076112, "longitude": 6.975243131497251}}'),
	('c1f5eed0-ca4d-440c-8faf-3db89bc2de61', 'c93c9406-5404-4822-8749-62761ff285f2', '7d26c101-dc52-492b-8531-3f2ead83f005', 'invalid_location', '2026-04-30 22:34:45.484742+00', 438321.43846675, 7.39, 3.98, 'Igbani Angus Claude', '197.210.55.158', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36 Edg/147.0.0.0', '{"error": "outside_geofence", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "049bd00b-a053-4a36-9c22-415f477f172e", "user_location": {"latitude": 7.39, "longitude": 3.98}}'),
	('c3963ee0-9bd4-4a91-9503-351700183e5a', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_in', '2026-04-30 23:09:17.927052+00', 57.43765766218322, 4.808309, 6.97582, 'Igbani angus Claude', '197.210.55.158', 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Mobile Safari/537.36 Edg/147.0.0.0', '{"event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808309, "longitude": 6.97582}}'),
	('0d4b58b5-330b-4717-b34c-d570d177672b', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '7d26c101-dc52-492b-8531-3f2ead83f005', 'clock_out', '2026-05-01 04:18:09.852616+00', 21.992345993492194, 4.808013347097263, 6.975693748266695, 'Igbani angus Claude', '102.89.82.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "You cannot clock out until the event has officially ended.", "event_id": "7d26c101-dc52-492b-8531-3f2ead83f005", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808013347097263, "longitude": 6.975693748266695}}'),
	('12418397-03b3-44d0-bb04-775995b4fc7f', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '83418de7-e1e4-4ef8-8261-c4e598d71fcd', 'clock_in', '2026-05-01 05:21:48.448804+00', 9.530262670976725, 4.808480036574983, 6.975222042024931, 'Igbani angus Claude', '105.116.13.224', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"event_id": "83418de7-e1e4-4ef8-8261-c4e598d71fcd", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808480036574983, "longitude": 6.975222042024931}}'),
	('d75b53ab-f5a8-49b9-974a-951553f06a73', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '83418de7-e1e4-4ef8-8261-c4e598d71fcd', 'clock_out', '2026-05-01 05:34:40.125847+00', 11.571902434018217, 4.808490484560929, 6.975201582571459, 'Igbani angus Claude', '102.89.82.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "You cannot clock out until the event has officially ended.", "event_id": "83418de7-e1e4-4ef8-8261-c4e598d71fcd", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808490484560929, "longitude": 6.975201582571459}}'),
	('2689e226-a97f-4274-ae4e-8929f5971b98', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '83418de7-e1e4-4ef8-8261-c4e598d71fcd', 'clock_out', '2026-05-01 05:50:54.360682+00', 12.152615656877403, 4.808484687280435, 6.975197021172017, 'Igbani angus Claude', '102.89.82.213', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "You cannot clock out until the event has officially ended.", "event_id": "83418de7-e1e4-4ef8-8261-c4e598d71fcd", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808484687280435, "longitude": 6.975197021172017}}'),
	('5b06fc42-bbf7-4c25-88dc-a3d5a98dbb8c', 'f82d951d-a444-4f4d-b63b-d342582afdcd', 'c282f662-1d0d-44e1-af42-948514692085', 'clock_in', '2026-05-02 08:02:10.663464+00', 14.222880136780823, 4.808558345990501, 6.975190924234153, 'Igbani angus Claude', '102.89.68.192', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"event_id": "c282f662-1d0d-44e1-af42-948514692085", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808558345990501, "longitude": 6.975190924234153}}'),
	('c919672e-0b7d-4670-b114-46e6215467b7', 'f82d951d-a444-4f4d-b63b-d342582afdcd', 'c282f662-1d0d-44e1-af42-948514692085', 'clock_in', '2026-05-02 08:11:19.180792+00', 14.22659772752051, 4.808558350298506, 6.975190888833637, 'Igbani angus Claude', '102.89.68.192', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"event_id": "c282f662-1d0d-44e1-af42-948514692085", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808558350298506, "longitude": 6.975190888833637}}'),
	('1fdb6723-e795-4b59-a5cc-5aa82c5fe58e', 'f82d951d-a444-4f4d-b63b-d342582afdcd', 'c282f662-1d0d-44e1-af42-948514692085', 'clock_out', '2026-05-02 08:20:52.811034+00', 14.203613794346854, 4.80855830483776, 6.975191098170509, 'Igbani angus Claude', '102.89.68.192', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "event_not_ended", "event_id": "c282f662-1d0d-44e1-af42-948514692085", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.80855830483776, "longitude": 6.975191098170509}}'),
	('957c2799-81c4-4d5c-b982-52065ad8b7bc', 'f82d951d-a444-4f4d-b63b-d342582afdcd', 'c282f662-1d0d-44e1-af42-948514692085', 'clock_out', '2026-05-02 08:31:24.598673+00', 14.243579019916579, 4.808558356697879, 6.975190720429663, 'Igbani angus Claude', '102.89.68.192', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"error": "event_not_ended", "event_id": "c282f662-1d0d-44e1-af42-948514692085", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808558356697879, "longitude": 6.975190720429663}}'),
	('b67bb08e-081c-43e1-939f-1e900c109752', '049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', 'c282f662-1d0d-44e1-af42-948514692085', 'clock_in', '2026-05-02 09:10:50.847158+00', 16.111020545951572, 4.808438823858788, 6.975174040973107, 'Glory Okon Johnny', '105.116.14.226', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15', '{"event_id": "c282f662-1d0d-44e1-af42-948514692085", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808438823858788, "longitude": 6.975174040973107}}'),
	('79401cfc-ab57-43d2-97a1-d53ab72ecbd3', 'f82d951d-a444-4f4d-b63b-d342582afdcd', '4a353828-3229-49c4-9797-13bb7c84e311', 'clock_in', '2026-05-02 10:32:05.295934+00', 11.901698993141048, 4.808492095631881, 6.975198449315054, 'Igbani angus Claude', '102.89.68.192', 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/147.0.7727.99 Mobile/15E148 Safari/604.1', '{"event_id": "4a353828-3229-49c4-9797-13bb7c84e311", "branch_id": "f20d9454-5ceb-4d49-a9d7-a608bfb2bb53", "department_id": "dcea05e8-fc39-4851-935c-808643593c73", "user_location": {"latitude": 4.808492095631881, "longitude": 6.975198449315054}}');


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."posts" ("id", "department_id", "target_type", "title", "body", "created_by", "modified_by", "created_at", "modified_at", "is_pinned", "is_archived", "reaction_counts", "comments_count", "branch_id", "more") VALUES
	('11111111-1111-1111-1111-111111111111', NULL, 'branch', 'Welcome to March 2026', 'May this new month bring divine acceleration to every member of the WPCC family.', 'c93c9406-5404-4822-8749-62761ff285f2', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', true, false, '{"like": 1, "love": 1}', 2, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('06e3c10c-7ff4-47c9-a10e-c203e59aaf47', NULL, 'global', 'hello', 'this is a test post', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-06 00:34:43.420331+00', '2026-03-06 00:34:43.420331+00', false, false, '{}', 0, NULL, '{}'),
	('1c310682-f273-41c6-abeb-8fa7825a7465', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Embracing Community Growth', 'Community growth is not just about increasing numbers; it is about deepening our connections and fostering a culture of mutual support. Over the next quarter, we will be focusing on initiatives that bring us closer together and empower every member to contribute meaningfully. We encourage everyone to participate in our upcoming workshops and community forums. Your voice matters, and together we can build a stronger, more resilient network that thrives on shared values and collective aspirations. Let''s embark on this journey with enthusiasm and a commitment to excellence.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('51c94690-14f9-427b-af85-177dee3fc6ee', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Innovation and Strategy Update', 'As we navigate the evolving landscape of our industry, innovation remains at the core of our strategy. We are actively exploring new methodologies and tools that will streamline our processes and enhance our overall effectiveness. I want to highlight the incredible work done by our research team, whose insights have paved the way for several exciting upcoming projects. It is crucial that we maintain a forward-thinking mindset, turning challenges into opportunities for growth. I invite all of you to share your innovative ideas; let''s continuously push the boundaries of what we can achieve.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('1a507595-54d3-4463-a5bc-f5b09fd4e694', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Cultivating a Culture of Feedback', 'Constructive feedback is the cornerstone of personal and professional development. To truly excel as a team, we must create an environment where feedback is not only welcomed but actively sought. I encourage everyone to engage in open, honest dialogues with one another. Whether it is praising a colleague for a job well done or offering suggestions for improvement, these interactions are vital. Let''s ensure that our feedback is always respectful, specific, and actionable. By cultivating this culture, we empower each other to reach our full potential.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('8745de91-9eb5-4c63-b4f6-148df7afa6b9', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Prioritizing Wellness and Balance', 'In our fast-paced environment, it can be easy to lose sight of our personal well-being. However, true success is unsustainable without maintaining a healthy work-life balance. I want to remind everyone to prioritize their mental and physical health. Take your breaks, disconnect when needed, and utilize the wellness resources available to you. We are implementing new flexible scheduling options to better support your needs. Remember, a rested and rejuvenated mind is far more productive and creative. Let''s work together to ensure we are all taking care of ourselves and each other.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('9f08d55b-9b73-438c-9887-f840cfcd330e', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Celebrating Recent Milestones', 'Take a moment to reflect on the remarkable milestones we have achieved recently. Our collective dedication has resulted in significant progress across all major initiatives. I am incredibly proud of the resilience and hard work demonstrated by every team member. These achievements are a testament to what we can accomplish when we collaborate with focus and purpose. As we celebrate these successes, let us also look forward to the new challenges ahead with the same vigor and determination. Thank you all for your extraordinary contributions.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('4af13659-3953-4f5c-b643-bf0a054e1c0a', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'The Importance of Continuous Learning', 'The world is changing rapidly, and so must we. Continuous learning is essential for staying competitive and relevant in our respective fields. I strongly encourage you all to dedicate time to upskilling, whether through formal courses, reading, or simply learning from one another. We will be investing more heavily in training programs over the coming months. Embrace curiosity and never settle for the status quo. The knowledge we acquire today will be the foundation of our innovations tomorrow.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('4d76f056-c658-433a-bf87-b609b3faf0bf', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Enhancing Collaboration Across Teams', 'Silos are the enemy of innovation. To achieve our overarching goals, we must actively break down barriers between departments and foster seamless collaboration. We are introducing new cross-functional projects designed to bring diverse skill sets together. By sharing knowledge and leveraging our unique perspectives, we can tackle complex problems more effectively. I challenge everyone to reach out to colleagues outside of their immediate team this week. Let''s build stronger bridges and work as one unified organization.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('5ba95824-8cb2-4fa3-a588-52215318d77c', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Revisiting Our Core Values', 'In times of significant change, it is helpful to anchor ourselves to our core values. They are the guiding principles that define who we are and how we operate. Over the next month, we will be hosting sessions to discuss how we can better integrate these values into our daily work. Integrity, excellence, and collaboration should be evident in every interaction and every decision we make. Let''s use these values as our North Star, ensuring that our actions consistently reflect our commitments.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('88888888-8888-8888-8888-888888888888', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Monthly 3-Day Fasting', 'Our congregational fast begins this Monday. Breaking session at the church hall by 5 PM.', '5a1d5b85-b39e-440e-a5f0-656b8097a165', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"fire": 1, "like": 1}', 2, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('33333333-3333-3333-3333-333333333333', 'bd5f7833-cd47-48c7-8334-2c403d2d4aa0', 'department', 'Switch Generation Youth Summit', 'Registration is officially open! Theme: High Performance Faith. Don''t miss out.', 'c93c9406-5404-4822-8749-62761ff285f2', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"like": 2}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('22222222-2222-2222-2222-222222222222', 'bd5f7833-cd47-48c7-8334-2c403d2d4aa0', 'branch', 'Mid-week Service: The Power of Grace', 'Join us online this Wednesday at 6:00 PM as we dive deep into the Book of Ephesians.', '5a1d5b85-b39e-440e-a5f0-656b8097a165', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"like": 2}', 6, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('99999999-9999-9999-9999-999999999999', NULL, 'global', 'Branch Anniversary Celebration', 'Celebrating 10 years of God''s faithfulness. Join the banquet on Friday.', 'c93c9406-5404-4822-8749-62761ff285f2', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"fire": 1, "like": 1}', 5, NULL, '{}'),
	('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'department', 'Financial Stewardship Seminar', 'Learning biblical principles for wealth creation and kingdom investment.', '5a1d5b85-b39e-440e-a5f0-656b8097a165', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"like": 2}', 1, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('44444444-4444-4444-4444-444444444444', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'branch', 'Weekly Prayer Points', 'This week we are upholding our church leadership and the community outreach teams in prayer.', '5a1d5b85-b39e-440e-a5f0-656b8097a165', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"fire": 1, "love": 1}', 1, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('55555555-5555-5555-5555-555555555555', NULL, 'branch', 'Community Outreach Success', 'We reached over 200 families during last Saturday''s food drive. Glory to God!', 'c93c9406-5404-4822-8749-62761ff285f2', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"fire": 1, "pray": 1}', 1, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('66666666-6666-6666-6666-666666666666', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Media Team Recruitment', 'We are looking for graphic designers and video editors. Apply through the app today.', '5a1d5b85-b39e-440e-a5f0-656b8097a165', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"like": 1, "love": 1}', 1, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('77777777-7777-7777-7777-777777777777', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Bible Study: Acts Chapter 2', 'Understanding the fire of the Holy Spirit and the birth of the early church.', 'c93c9406-5404-4822-8749-62761ff285f2', NULL, '2026-03-01 18:48:31.519908+00', '2026-03-01 18:48:31.519908+00', false, false, '{"like": 2}', 1, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('6cc2e69b-d627-43e2-978d-3137acd2d690', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'Looking Ahead: The Next Quarter', 'As we approach the new quarter, it is time to shift our focus towards strategic execution. We have laid out ambitious goals, and achieving them will require disciplined effort and alignment. We will be finalizing our quarterly objectives by next week. I ask that all teams review their specific targets and proactively identify any potential roadblocks. Let''s approach this upcoming period with a proactive mindset and a clear sense of priorities. I am confident that we will exceed expectations once again.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}'),
	('1b57a410-6549-42b1-acdb-afb7b46a8fbe', 'd7bfc422-b0b1-494d-8e55-8398317988a3', 'department', 'A Message of Gratitude', 'I want to take a moment simply to say thank you. Your hard work, passion, and commitment are what make this community truly special. We have navigated significant challenges recently, and we have done so with grace and teamwork. I am constantly inspired by the dedication I see from each of you every single day. Please know that your efforts do not go unnoticed. Thank you for making this such a wonderful place to work and grow. Let''s continue to support one another and achieve great things together.', 'f3732027-f05a-423c-a51a-ca2bda86b2f2', NULL, '2026-03-21 13:00:59.442165+00', '2026-03-21 13:00:59.442165+00', false, false, '{}', 0, '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '{}');


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."comments" ("id", "post_id", "parent_comment_id", "created_by", "body", "created_at", "modified_at", "is_edited", "is_deleted", "more", "commentor name") VALUES
	('672c963b-59ac-4cff-81a6-af0214e4b7db', '55555555-5555-5555-5555-555555555555', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'Looking forward to the anniversary banquet!', '2026-02-25 00:34:29.704645+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('3c10bd4e-4d2d-4cc0-ba14-7eacd614cd07', '22222222-2222-2222-2222-222222222222', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Looking forward to the anniversary banquet!', '2026-02-23 17:56:21.868479+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('26d74bc9-f5bc-4bf8-8247-2578f0ec345d', '88888888-8888-8888-8888-888888888888', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'Thanks for sharing these prayer points.', '2026-02-26 05:32:05.070501+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('b77eadae-0066-4ec0-8271-ddc306da3777', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'The Media Team is doing a fantastic job with the visuals.', '2026-02-24 20:46:30.838937+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('a71c6b1a-a84a-4bfb-9db2-7b4f1207862e', '22222222-2222-2222-2222-222222222222', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'So proud of what our branch is achieving!', '2026-02-23 14:48:07.100512+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('70473642-e7b2-4cff-b8ad-c0cfbe43be47', '88888888-8888-8888-8888-888888888888', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'Amen! This is exactly what I needed to hear today.', '2026-02-26 02:25:34.011965+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('07ea7141-8451-4137-833f-801a471cb97f', '99999999-9999-9999-9999-999999999999', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Thanks for sharing these prayer points.', '2026-02-28 14:17:47.887343+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('6e0c16ec-f58e-4992-92e8-f2e7dcd63644', '11111111-1111-1111-1111-111111111111', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Amen! This is exactly what I needed to hear today.', '2026-02-25 18:01:51.07829+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('9fb1804c-f17c-442c-b3d9-9b9974ab298f', '99999999-9999-9999-9999-999999999999', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'This teaching on stewardship was so eye-opening.', '2026-02-23 21:44:00.048557+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('71813324-de15-4e87-933e-1685417b47d3', '22222222-2222-2222-2222-222222222222', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'This teaching on stewardship was so eye-opening.', '2026-02-23 12:57:25.686977+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('27d1aa78-b02b-4b16-b93f-22130e8ef604', '22222222-2222-2222-2222-222222222222', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'Glory to God for this wonderful update.', '2026-02-25 13:05:43.20882+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('c2e74001-c59b-46e6-85e2-78e44d54534f', '66666666-6666-6666-6666-666666666666', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Thanks for sharing these prayer points.', '2026-02-24 07:35:01.533397+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('900fe4ba-a989-433b-a402-d1d83d84eca9', '22222222-2222-2222-2222-222222222222', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'The Media Team is doing a fantastic job with the visuals.', '2026-02-27 16:42:05.450386+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('bdbd9f4d-d4b7-4386-8995-ecde69679371', '99999999-9999-9999-9999-999999999999', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Amen! This is exactly what I needed to hear today.', '2026-02-25 17:03:31.350815+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('51ea22e5-b34b-4291-a2ec-4e2ef645c7be', '99999999-9999-9999-9999-999999999999', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Looking forward to the anniversary banquet!', '2026-02-28 20:28:26.336266+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('6a2a3b1e-d424-440b-9874-44c2f633423a', '99999999-9999-9999-9999-999999999999', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'The Media Team is doing a fantastic job with the visuals.', '2026-02-27 03:02:12.138803+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('50355244-5fa3-4b83-a251-7794553b4963', '11111111-1111-1111-1111-111111111111', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'Looking forward to the anniversary banquet!', '2026-02-28 03:57:42.057552+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('a52b734d-ca70-4821-8ffa-8bf3e366d77d', '22222222-2222-2222-2222-222222222222', NULL, '5a1d5b85-b39e-440e-a5f0-656b8097a165', 'The Media Team is doing a fantastic job with the visuals.', '2026-02-23 18:56:07.110081+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('09f5a4c2-324a-4b76-a2e3-d6c6ebd9dca1', '77777777-7777-7777-7777-777777777777', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Amen! This is exactly what I needed to hear today.', '2026-02-24 00:06:36.305556+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL),
	('d5fc84af-befa-4256-a56c-67fcc1b3db34', '44444444-4444-4444-4444-444444444444', NULL, 'c93c9406-5404-4822-8749-62761ff285f2', 'Thanks for sharing these prayer points.', '2026-02-26 07:08:00.279001+00', '2026-03-01 19:10:10.567741+00', false, false, NULL, NULL);


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: course_enrollments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: department_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: global_admins; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: roletypes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."roletypes" ("id", "rolename", "description") VALUES
	('3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'member', 'Regular church member'),
	('de391225-d832-4dd5-8979-fb754c54ca9f', 'worker', 'a church member that belongs to a department'),
	('b8326342-51b6-42e1-a870-f66633340a8e', 'admin', 'An administrator in a church branch'),
	('afac070f-64f5-4377-984a-de9b0903c2ce', 'globaladmin', 'The global church leader, presides over branches'),
	('975d166a-6cf9-46c4-b3ca-7cc7fdc8f38f', 'Directorate', 'Workers directorate'),
	('e5bc92ad-b7e4-4ae3-af3f-12ec9e15f190', 'dept_leader', 'a leader of a church department')
ON CONFLICT ("rolename") DO NOTHING;


--
-- Data for Name: leadership_titles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."leadership_titles" ("id", "code", "name", "description", "parent_role_id", "created_at") VALUES
	('f97508b2-566e-4572-ba13-76c96f2682ac', 'hod', 'HOD', 'Head of department', 'e5bc92ad-b7e4-4ae3-af3f-12ec9e15f190', '2026-06-25 20:25:04.022722+00'),
	('f991b5ef-ec02-433d-b972-18a7b12082bc', 'pro', 'PRO', 'Public relations officer', 'e5bc92ad-b7e4-4ae3-af3f-12ec9e15f190', '2026-06-25 20:25:04.022722+00'),
	('de3b99dc-5f29-4d8d-897d-601a97bc0700', 'department_officer', 'Department Officer', 'Fallback departmental leadership title for migrated legacy records', 'e5bc92ad-b7e4-4ae3-af3f-12ec9e15f190', '2026-06-25 20:25:04.022722+00'),
	('01c9cb99-b1b7-40e1-b436-944c11a8bc1e', 'financial_secretary', 'Financial Secretary', 'Departmental financial secretary', 'e5bc92ad-b7e4-4ae3-af3f-12ec9e15f190', '2026-06-25 20:25:04.022722+00')
ON CONFLICT ("code") DO NOTHING;


--
-- Data for Name: leaders; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: membershipcode; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."membershipcode" ("memberid", "membershipcode") VALUES
	('620ec5dd-b6f7-57a2-b08e-dbd81ece9ce1', '0065-1'),
	('73014d1d-2851-54b1-a706-f1ee6868d407', '0063-1'),
	('16fa675d-23c2-5e11-9fb2-33e0f5eccfdc', '0064'),
	('dc6f0db4-4c33-5a1f-9efd-456e0fecebf8', '0050'),
	('a00f4b5b-696e-5810-a7b1-1fe1d5303198', '0051'),
	('9bb5cc87-d189-5067-9947-93d95e4ae873', '0057'),
	('a1ab1dba-c790-5afe-89ae-2cab65f2f0c0', '0058'),
	('7de1a2ec-cd94-5f4a-894c-5b663bf32a99', '0060'),
	('f837bd63-9f89-53b1-91a5-8e99446d1bf9', '0061'),
	('82af049e-1ab6-5599-8805-728b6d081f21', '0062'),
	('20d88ef5-cbf9-510b-aa82-eb06ba097b6a', '0063'),
	('5639f727-44f2-5177-ad54-8c8bb61864f1', '0054-1'),
	('6262453e-52b0-5844-8da8-00a6f477eb3b', '0056-1'),
	('db838aba-1c49-5517-90c7-0105342a392c', '0065'),
	('27dfcf5e-5182-5882-9654-722a945eef50', '0066'),
	('93616239-014c-535e-9907-743cc3984e03', '0067'),
	('0bd73ba6-01a2-51a7-897d-606ecb6ee2f3', '0068'),
	('d88ebca9-5481-55ec-8930-b5ee10fd9d39', '0069'),
	('fd46d9f0-567f-59ac-870a-289308fb0537', '0072'),
	('ee6e16f1-b774-5c48-bf9a-8489108e6be2', '0073'),
	('fa4b9146-3e7d-5466-a2fb-0a3fb4f7634b', '0076'),
	('4388937c-0663-5c19-9326-df1497aae772', '0077'),
	('6ca918ed-e773-52ae-9f82-6685d81f73bf', '0078'),
	('c5ae808b-48b6-5575-b032-4983f9d1751c', '0065-2'),
	('7edafbb8-d2b2-584e-be78-f1f5a17e2a22', '0066-1'),
	('fcbded63-f969-5559-a25e-821a639be14c', '0146'),
	('7cd5e1ec-3cce-5f92-876d-c8acdd30a0d3', '/HQ/'),
	('f82d951d-a444-4f4d-b63b-d342582afdcd', '0104'),
	('cdd47eec-8545-5582-9658-6cf0d40ae0e1', '0067-1'),
	('84f9c52e-1a16-57ea-8d62-7589c3e875cf', '0068-1'),
	('7c3edc10-5798-5c10-86fa-a5205b724472', '0069-1'),
	('46d0856e-9f34-56a5-b954-6246d3647b4c', '0070'),
	('0a87aff0-1493-580f-a263-03bc8a28fdac', '0071'),
	('11e9782c-3d90-53df-a276-5809d8e22197', '0079'),
	('6c400f3e-a082-5371-b4d6-1a924fd575f4', '0082'),
	('ae94c95c-a8e7-5546-a35d-053aa2cffed0', '0085'),
	('7bfbf62d-d417-5d06-abed-6c922b4c8827', '0088'),
	('41a8efe7-56d9-52da-9e48-48735d9d4fab', '0089'),
	('e1c3c4c8-b903-5f1c-9149-f171031f4252', '0091'),
	('0b153e44-0f42-5195-8754-2737ca5dc94b', '0095-1'),
	('0affa6e3-51cd-5955-b7ac-720eb6a8bd99', '0096'),
	('87cbe629-a4c0-5935-bee6-32f17be82cea', '0097'),
	('2fe4c83f-97e0-5a73-a54d-79e056c795af', '0101'),
	('15458965-71f0-5401-bcbb-be5916bcf63d', '0105'),
	('049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', '0106'),
	('c9a2840c-c6c6-5f77-8d83-515fc1f944dc', '0109'),
	('12dc39be-d1f0-5150-9162-8c5cd15a4f83', '0111'),
	('2a1ea96f-02e1-598d-a7e1-0d023a520ef6', '0090'),
	('6c186f2c-94b9-5c34-bf35-9de4a83a4efd', '0013'),
	('4a9b8455-2e2c-5310-9ff0-d91fc1aabb05', '0112'),
	('46e9b6c8-991c-5c7b-8b2d-74597c54173e', '0115'),
	('d06a4ea7-0373-5cdf-9f4a-b66cc0f9c6f1', '0119'),
	('55c2775d-2e55-58a1-a6f5-2d036208cab3', '0125'),
	('6f5def03-569a-5095-9201-c2626d894e70', '0122'),
	('f8c18b92-e5e3-5b29-b7e8-9a7dbff338ae', '0123'),
	('b8296b18-2881-56b0-8f8b-5da2a2c53e03', '0124'),
	('fbd5d811-c3e5-59a1-b9a4-06bfb166dd7b', '0126'),
	('d4bb3016-28da-5bda-8bf8-d5f3b49f5870', '0128'),
	('d6354343-e7f2-5cb4-a4f1-e26cb99f1a30', '0131'),
	('afce8e7b-e114-518b-a169-c2c1261554cd', '0132'),
	('eee782a8-5009-5a7b-bff6-0be616e4b2f7', '0138'),
	('19197c6e-2404-53f2-b618-026745017abc', '0139'),
	('90556612-dd95-54aa-b469-a9aeff809687', '0052'),
	('4aed5d09-24fc-57e2-b763-1fb1d87e4cc3', '0107'),
	('33e87363-203d-55b1-a607-8dca27a46eed', '0040'),
	('182f6be1-65f3-5289-bde1-7833f1f17a71', '0021'),
	('836e1d11-b1fd-5c86-8f52-e25973dc0712', '0049'),
	('a70f0fe0-2a30-5868-a046-00ebc1843f64', '0041'),
	('85ea5802-7ba1-5ff9-a8ab-52f8f965c84d', '0055'),
	('1f47e3e6-55d8-5012-bccb-109553f8a2a0', '0095'),
	('b243ea46-f950-5c14-ab42-7c8dbc08fdf6', '0133'),
	('b4caed66-5496-53ce-b229-34c82e9a235b', '0093'),
	('5c0fd8c2-6c72-5e5e-b2bc-782559bf1e7a', '0136'),
	('62f487e2-453a-428c-91ba-66349cc82251', '0001'),
	('11641715-8db0-50bb-b41f-2fc14aa7122d', '0019'),
	('7bc7082a-e83e-5127-9db1-be3962f53d9e', '0086'),
	('57bfc01d-8315-5cbe-9bf0-5d9fa4a34a5c', '0006'),
	('f585dde3-a79e-50c3-9aad-4c9f321f00b0', '0007'),
	('f7894dcb-2794-5a0d-9e0b-0f640efbf80c', '0009'),
	('74b41b31-0adc-59b8-9693-4683560913fd', '0034'),
	('0ef80e26-1f47-52a8-882e-660f3036ccc2', '0010'),
	('344aa4cd-5f9c-5288-819b-3b9ae2095af7', '0012'),
	('2b98f83f-35a0-5dcc-b86f-7fa5ebe303f4', '0015'),
	('d510924a-5e33-5f69-be69-0982dfe7f0e7', '0016'),
	('5528e385-375b-53db-baa4-fcde2f4f7206', '0017'),
	('b0a90f0d-da25-5533-9e54-b61ca723e8e0', '0018'),
	('9ee0ff4f-80fc-5e45-aa1f-056c0b346008', '0020'),
	('33689fc4-d9fb-5905-b41d-4aa3d6f28813', '0038'),
	('9c13f991-e95c-5b4b-9c8c-b5aecd907a3a', '0042'),
	('63625f49-e9fb-5571-80ab-b94a3044e8c5', '0043'),
	('cf80d0e1-b26b-536a-b4a0-b25bc83ac591', '0044'),
	('114ab3f4-0f8c-5f01-be8b-ecc32729cf87', '0045'),
	('4668c1ea-b2f0-51fa-a4d1-41096c6792f7', '0047'),
	('a65cf3a7-40b1-5bd1-92cc-a0f4db703ab6', '0049-1');


--
-- Data for Name: otp_cooldowns; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."otp_cooldowns" ("membership_code", "last_sent_at") VALUES
	('0001', '2026-05-01 06:15:40.063+00'),
	('0106', '2026-05-02 09:18:24.679+00'),
	('0107', '2026-05-02 09:24:55.272+00'),
	('0104', '2026-06-26 10:28:06.954+00');


--
-- Data for Name: penalties; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: post_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."post_reactions" ("id", "post_id", "reaction_type", "user_id", "created_at") VALUES
	('4410af89-6028-4fcc-b53e-90490946b7fc', '11111111-1111-1111-1111-111111111111', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('6a86c720-fff1-4470-929d-e36a5e013771', '11111111-1111-1111-1111-111111111111', 'love', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('cac951e3-a0d9-4148-95c6-4424acdc6445', '22222222-2222-2222-2222-222222222222', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('2ec32613-bc22-4a68-b68e-d62115f468c5', '22222222-2222-2222-2222-222222222222', 'like', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('b4d313d1-12ac-4cbe-bbbe-91302a10614e', '33333333-3333-3333-3333-333333333333', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('59e1efa4-1791-4a1d-8f3d-bb27224212f4', '33333333-3333-3333-3333-333333333333', 'like', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('51434fae-f8b2-4fb9-90d6-6913eac84229', '44444444-4444-4444-4444-444444444444', 'fire', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('8b85aa54-6479-47e5-832c-7a56784eb740', '44444444-4444-4444-4444-444444444444', 'love', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('7edb7c80-1403-4b57-9d77-78bda17df842', '55555555-5555-5555-5555-555555555555', 'fire', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('6dc5b7f1-9589-4409-b662-112722d2a4e0', '55555555-5555-5555-5555-555555555555', 'pray', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('ad40efbf-f494-4b97-bb7f-192c45a439f6', '66666666-6666-6666-6666-666666666666', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('a2a36532-4030-4822-984e-9014e3eb7f63', '66666666-6666-6666-6666-666666666666', 'love', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('dbc65a7e-23ae-4fde-b4e2-2408ff41d8da', '77777777-7777-7777-7777-777777777777', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('65a992c7-9e63-4914-8a1c-ffb187b7ee44', '77777777-7777-7777-7777-777777777777', 'like', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('d895fa11-cb07-47be-9303-1cbfa365c51b', '88888888-8888-8888-8888-888888888888', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('4586b913-ceb9-44db-a4b6-b790e465f989', '88888888-8888-8888-8888-888888888888', 'fire', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('72f5d897-1791-4b45-9e43-26268707c842', '99999999-9999-9999-9999-999999999999', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('59f515cb-169b-4b9a-91ff-f28200838092', '99999999-9999-9999-9999-999999999999', 'fire', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00'),
	('32749dbf-6768-43d8-8d5b-bf4756706c87', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'like', 'c93c9406-5404-4822-8749-62761ff285f2', '2026-03-01 19:42:59.311115+00'),
	('c89de437-61a1-42f1-856d-7a8fd920ea0b', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'like', '5a1d5b85-b39e-440e-a5f0-656b8097a165', '2026-03-01 19:42:59.311115+00');


--
-- Data for Name: profiles_priv_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."profiles_priv_info" ("id", "branch_id", "department_id", "role", "full_name", "phone", "bio", "membership_code", "date_joined", "verified", "created_at", "dob", "occupation", "address", "email", "avatar", "lastname", "firstname", "profilecomplete", "prefix", "date_of_birth", "gender", "marital_status", "phone_number", "residential_address", "date_joined_wpcc", "water_baptism_date", "maturity_class_completed", "ministry_class_completed", "mission_class_completed", "emergency_contact") VALUES
	('fa4b9146-3e7d-5466-a2fb-0a3fb4f7634b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Moshood Aminat Fumilayo', '8181244117', NULL, '0076', '2026-04-08', false, '2026-04-08 07:16:59.114499', '2026-11-01', 'Fashion Designer', '29 psyacthtric road', 'aminamoshood89@gmail.com', NULL, 'Aminat Fumilayo', 'Moshood', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('4388937c-0663-5c19-9326-df1497aae772', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Moshood Aisha O.', '8144147344', NULL, '0077', '2024-05-01', false, '2026-04-08 07:16:59.114499', '2026-07-05', 'Mechanical engineer', '29 psyacthtric road', 'aisha4life98@gmail.com', NULL, 'Aisha O.', 'Moshood', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Glory Okon Johnny', '9046606929', NULL, '0106', '2020-02-16', false, '2026-04-08 07:21:47.544856', '2026-02-02', 'Product marketer', '3 johnpaul close of NTA Road', 'johnnygloryokon@gmail.com', NULL, 'Okon Johnny', 'Glory', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, '3 johnpaul close of NTA Road', NULL, NULL, 'yes', NULL, NULL, '9067460192'),
	('b8296b18-2881-56b0-8f8b-5da2a2c53e03', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Juliet Akioya', '8033692959', NULL, '0124', '2026-04-08', false, '2026-04-08 07:27:32.215241', '2026-05-01', 'Fashion Designer', 'Agip', 'jakioya@gmail.com', NULL, 'Akioya', 'Juliet', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Agip', NULL, NULL, 'yes', NULL, NULL, NULL),
	('f82d951d-a444-4f4d-b63b-d342582afdcd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Igbani angus Claude', '9132652134', NULL, '0104', '2026-04-08', false, '2026-04-08 08:11:23.082382', '2026-09-02', 'Software Engr.', 'Rd4, Block 10 b, Agip estate rumueme portharcourt', 'igbaniangus@gmail.com', NULL, 'angus Claude', 'Igbani', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('11e9782c-3d90-53df-a276-5809d8e22197', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Balogun Yemisi', '8167602331', NULL, '0079', '2026-04-08', false, '2026-04-08 07:18:17.835044', NULL, 'Baker', 'Extension B Agip estate', 'olayemisibalogun@gmail.com', NULL, 'Yemisi', 'Balogun', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Extension B Agip estate', NULL, NULL, 'yes', NULL, NULL, NULL),
	('a1ab1dba-c790-5afe-89ae-2cab65f2f0c0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Siminialaiyim Flourish Apollos', '7017229158', NULL, '0058', '2026-04-07', false, '2026-04-07 21:42:01.573109', '2026-04-15', 'Student', '15 Dan Ikeagwu st, off Aker rd', 'flourishapollos84@gmail.com', NULL, 'Flourish Apollos', 'Siminialaiyim', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('20d88ef5-cbf9-510b-aa82-eb06ba097b6a', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Uchechi Godspower Godwin', '8033100652', NULL, '0063', '2026-04-07', false, '2026-04-07 21:42:33.60788', '2026-11-28', 'Student', 'Road 4 plot 11 Agipp estate', 'godspowerogorchukwu@gmail.com', NULL, 'Godspower Godwin', 'Uchechi', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('c9a2840c-c6c6-5f77-8d83-515fc1f944dc', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Siminialaiyim Conqueror Apollos', '8100514217', NULL, '0109', '2026-04-08', false, '2026-04-08 07:21:47.544856', '2026-03-19', 'Employed', 'Elioparanwo Road', 'conquerorapollos@gmail.com', NULL, 'Conqueror Apollos', 'Siminialaiyim', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Elioparanwo Road', NULL, NULL, 'yes', NULL, NULL, NULL),
	('dc6f0db4-4c33-5a1f-9efd-456e0fecebf8', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Favour Abbey', '8032758696', NULL, '0050', '2026-04-07', false, '2026-04-07 21:42:01.573109', '2026-05-02', 'Social Worker', 'Rd 21 Federal Housinf Estate', 'favourowen@gmail.com', NULL, 'Abbey', 'Favour', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('a00f4b5b-696e-5810-a7b1-1fe1d5303198', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Hope Saturday Nuka', '9031763784', NULL, '0051', '2026-04-07', false, '2026-04-07 21:42:01.573109', '2026-02-04', 'Student', 'Ogalink Farm Road Eleme', 'saturdayhope96@gmail.com', NULL, 'Saturday Nuka', 'Hope', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('fd46d9f0-567f-59ac-870a-289308fb0537', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Eniye Ehighakwo', '8036829274', NULL, '0072', '2026-04-08', false, '2026-04-08 07:16:59.114499', '2026-10-12', 'Business', '16 Road 1 Extension Agip Estate', 'oseeniye@gmail.com', NULL, 'Ehighakwo', 'Eniye', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('fbd5d811-c3e5-59a1-b9a4-06bfb166dd7b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Idara Lawrence Tom Bob Manuel', '8025971777', NULL, '0126', '2026-04-08', false, '2026-04-08 07:27:32.215241', '2026-05-15', 'Business', 'Agip Estate', 'trendybobmanuel@gmail.com', NULL, 'Lawrence Tom Bob Manuel', 'Idara', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Agip Estate', NULL, NULL, 'yes', NULL, NULL, '7025149505'),
	('d4bb3016-28da-5bda-8bf8-d5f3b49f5870', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Daniella Neriton Prefa Zikere', '9131601607', NULL, '0128', '2026-04-08', false, '2026-04-08 07:27:32.215241', '2026-09-11', 'Student', 'NTA', 'zikereneritonprefa@gmail.com', NULL, 'Neriton Prefa Zikere', 'Daniella', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'NTA', NULL, NULL, 'yes', NULL, NULL, NULL),
	('9bb5cc87-d189-5067-9947-93d95e4ae873', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Esther Adaeze Michael', '8169395893', NULL, '0057', '2026-04-07', false, '2026-04-07 21:42:01.573109', '2026-02-03', 'Entrepreneur', 'Chinda Road', 'adamichael2019@gmail.com', NULL, 'Adaeze Michael', 'Esther', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('7de1a2ec-cd94-5f4a-894c-5b663bf32a99', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Joyce Okah', '8037774998', NULL, '0060', '2026-04-07', false, '2026-04-07 21:42:01.573109', '2026-07-10', 'Businnes', '14 lucky st, Agip Estate', 'ajiejoyceonyi@gmail.com', NULL, 'Okah', 'Joyce', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('f837bd63-9f89-53b1-91a5-8e99446d1bf9', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Omuku Patience', '7025816990', NULL, '0061', '2026-04-07', false, '2026-04-07 21:42:33.60788', '2026-04-18', 'Student', '3 lucky st Agip Estate', 'patienceomuku@gmail.com', NULL, 'Patience', 'Omuku', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('82af049e-1ab6-5599-8805-728b6d081f21', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Peace Ajie', '8141208942', NULL, '0062', '2026-04-07', false, '2026-04-07 21:42:33.60788', '2026-06-21', 'Student', '14 LuCky St Agip Estate', 'peaceajie21@gmail.com', NULL, 'Ajie', 'Peace', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('5639f727-44f2-5177-ad54-8c8bb61864f1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Eboma Victory Ndu', '8143431980', NULL, '0054-1', '2026-04-07', false, '2026-04-07 21:42:33.60788', '2026-06-21', 'Bussiness', 'Rd 4 plot 11 Agip Estate', 'nduvictory.2023@gmail.com', NULL, 'Victory Ndu', 'Eboma', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('6262453e-52b0-5844-8da8-00a6f477eb3b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Okofor Gladys .E.', '7063162602', NULL, '0056-1', '2026-04-07', false, '2026-04-07 21:42:33.60788', '2026-06-25', 'Proprietress', '7 chief Thomas street', 'gladys.okofor@yahoo.com', NULL, 'Gladys .E.', 'Okofor', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('db838aba-1c49-5517-90c7-0105342a392c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Unuafe Zue', '8069357062', NULL, '0065', '2026-04-07', false, '2026-04-07 21:43:04.328479', '2026-10-18', 'Student', '14 Lucky St Agip Estate', 'unuafezue801@gmail.com', NULL, 'Zue', 'Unuafe', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('27dfcf5e-5182-5882-9654-722a945eef50', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Faith Reuben', '9017684949', NULL, '0066', '2026-04-07', false, '2026-04-07 21:43:04.328479', '2026-05-18', 'Student', 'No 2 Chief thomas st eagle Isand', 'reubenfaith73@gmail.com', NULL, 'Reuben', 'Faith', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('93616239-014c-535e-9907-743cc3984e03', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Chinonyerem Benson', '7025816990', NULL, '0067', '2026-04-07', false, '2026-04-07 21:43:04.328479', '2026-11-18', 'Student', 'Rd 12 flat 18 Housing estate', 'chinonyerembenson20@gmail.com', NULL, 'Benson', 'Chinonyerem', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('0bd73ba6-01a2-51a7-897d-606ecb6ee2f3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Godgift Ajie', '9031264875', NULL, '0068', '2026-04-07', false, '2026-04-07 21:43:04.328479', '2026-10-18', 'Student', '14 Lucky street Agip Estate', 'ajiegodgiftndu@gmail.com', NULL, 'Ajie', 'Godgift', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('d88ebca9-5481-55ec-8930-b5ee10fd9d39', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Esther Onyeche', '7025816990', NULL, '0069', '2026-04-07', false, '2026-04-07 21:43:04.328479', '2026-06-18', 'Student', 'Rd 12 flat 18 Housing estate', 'estheronyeche71@gmail.com', NULL, 'Onyeche', 'Esther', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('7cd5e1ec-3cce-5f92-876d-c8acdd30a0d3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Anodere Chalya', '7066397104', NULL, '/HQ/', '2026-04-08', false, '2026-04-08 08:11:23.082382', '2026-04-25', 'Business woman', 'Chinda Road', 'chalysange@gmail.com', NULL, 'Chalya', 'Anodere', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('fcbded63-f969-5559-a25e-821a639be14c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'worker', 'Mukoro Kesiena Abraham', '7038412469', NULL, '0146', '2026-04-08', false, '2026-04-08 08:11:23.082382', '2026-08-20', 'Scaffolder/Business', 'Eagle Island', 'k.mukoro@yahoo.com', NULL, 'Kesiena Abraham', 'Mukoro', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('ee6e16f1-b774-5c48-bf9a-8489108e6be2', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '23d94616-5401-45f5-94b8-c86584de853e', 'worker', 'Idu Daniella Chizi', '7039313765', NULL, '0073', '2026-04-08', false, '2026-04-08 07:16:59.114499', '2026-03-13', 'Student', 'Agip Estate', 'idudaniella19@gmail.com', NULL, 'Daniella Chizi', 'Idu', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('12dc39be-d1f0-5150-9162-8c5cd15a4f83', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Bright Chidera Osayi', '9057545074', NULL, '0111', '2026-04-08', false, '2026-04-08 07:21:47.544856', '2026-09-11', 'Student', 'Road 7 flat 11a', 'brightchidera23@gmail.com', NULL, 'Chidera Osayi', 'Bright', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Road 7 flat 11a', NULL, NULL, 'yes', NULL, NULL, NULL),
	('63625f49-e9fb-5571-80ab-b94a3044e8c5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Isaiah Awaji Moroiso Rejoice', '7015043018', NULL, '0043', '2026-04-07', false, '2026-04-07 21:40:51.818135', '2026-11-25', 'Student', 'Road 6 Flat 2b Agip Estate', 'awajimoroisoisaiah@gmail', NULL, 'Awaji Moroiso Rejoice', 'Isaiah', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 6 Flat 2b Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '8037473338'),
	('90556612-dd95-54aa-b469-a9aeff809687', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'worker', 'Kassin Hauwa Esther', '8034580273', NULL, '0052', '2025-10-01', false, '2026-04-07 21:28:20.097017', '2026-05-15', 'Bussiness', '23 Chief Thomas street', 'eliana4k@yahoo.com', NULL, 'Hauwa Esther', 'Kassin', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, '23 Chief Thomas street', NULL, NULL, NULL, NULL, NULL, '8038937919'),
	('2b98f83f-35a0-5dcc-b86f-7fa5ebe303f4', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Ebi Uchenna K', '8083119504', NULL, '0015', '2026-04-07', false, '2026-04-07 21:32:39.050584', '2026-02-17', 'Entreprenuer', 'Plot 24 R0ad 5 Agip Estate', 'kelzgracebiz@gmail.com', NULL, 'Uchenna K', 'Ebi', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, 'Plot 24 R0ad 5 Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '7030004803'),
	('9c13f991-e95c-5b4b-9c8c-b5aecd907a3a', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Grace Seifegha Warri Ebi', '7030004803', NULL, '0042', '2026-04-07', false, '2026-04-07 21:33:10.567939', '2026-02-10', 'Sailor', 'Road 5 Plot 24 Agip Estate', 'warrigrace@gmail.com', NULL, 'Seifegha Warri Ebi', 'Grace', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Road 5 Plot 24 Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '8083119504'),
	('6c400f3e-a082-5371-b4d6-1a924fd575f4', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Bolawatife Moshood', '9037491756', NULL, '0082', '2026-04-08', false, '2026-04-08 07:18:17.835044', '2026-05-11', 'Student & fashion designer', '29 psyacthtric road', 'oyelekeassana@gmail.com', NULL, 'Moshood', 'Bolawatife', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, '29 psyacthtric road', NULL, NULL, 'yes', NULL, NULL, '8144147344'),
	('4a9b8455-2e2c-5310-9ff0-d91fc1aabb05', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Joseph Akidy Israel', '9168051179', NULL, '0112', '2026-04-08', false, '2026-04-08 07:21:47.544856', '2026-08-15', 'Student', 'flat 14a road 6', 'josephakidyisrael@wisdompowercc.org', NULL, 'Akidy Israel', 'Joseph', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'flat 14a road 6', NULL, NULL, 'yes', NULL, NULL, '8055063012'),
	('d6354343-e7f2-5cb4-a4f1-e26cb99f1a30', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'worker', 'Godsfavour iheanomachi', '9165710685', NULL, '0131', '2026-04-08', false, '2026-04-08 07:27:32.215241', '2026-01-20', 'Student', 'Plot 11', 'godsfavour@gmail.com', NULL, 'iheanomachi', 'Godsfavour', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Plot 11', NULL, NULL, 'yes', NULL, NULL, '8067401830'),
	('b243ea46-f950-5c14-ab42-7c8dbc08fdf6', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Queen Elizabeth James Akyee', '9150707787', NULL, '0133', '2026-04-08', false, '2026-04-08 07:30:40.200729', '2026-02-23', 'Student/Personal Assistant', 'Peter Odili Road', 'queenelizabethjames3@gmail.com', NULL, 'Elizabeth James Akyee', 'Queen', false, 'WPCC/HQ/', NULL, 'f', 'Single', NULL, 'Peter Odili Road', NULL, NULL, 'yes', NULL, NULL, '7056944813'),
	('cf80d0e1-b26b-536a-b4a0-b25bc83ac591', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e14a403b-9739-45ef-8a24-b90866749318', 'worker', 'Emmanuel Johnson', '9112949907', NULL, '0044', '2026-04-07', false, '2026-04-07 21:40:51.818135', '2026-05-18', 'Teacher', 'Ada George', 'johnsonemmanuel@gmai.com', NULL, 'Johnson', 'Emmanuel', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Ada George', NULL, NULL, 'Yes', NULL, NULL, '7068433964'),
	('114ab3f4-0f8c-5f01-be8b-ecc32729cf87', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Nancy Azubuike', '8085978797', NULL, '0045', '2026-04-07', false, '2026-04-07 21:40:51.818135', '2026-05-02', 'Civil Servant', 'Accord Estatae off Okabie,Chinda', 'mzandre740@yahoo.com', NULL, 'Azubuike', 'Nancy', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Accord Estatae off Okabie,Chinda', NULL, NULL, 'Yes', NULL, NULL, '8036692959'),
	('33e87363-203d-55b1-a607-8dca27a46eed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Afoloyan Helen', '8067138589', NULL, '0040', '1905-07-15', false, '2026-04-07 21:28:20.097017', '2026-06-11', 'Instructor', 'Shell location off chinda road', 'akinola.toyosi@gmail.com', NULL, 'Helen', 'Afoloyan', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Shell location off chinda road', NULL, NULL, 'Yes', NULL, NULL, '8066369678'),
	('46e9b6c8-991c-5c7b-8b2d-74597c54173e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Cyril Victor', '7063718185', NULL, '0115', '2026-04-08', false, '2026-04-08 07:24:14.266395', '2026-12-23', 'Student', 'plot 10 road 10', 'cyrilvictorebubechukwu@gmail.com', NULL, 'Victor', 'Cyril', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'plot 10 road 10', NULL, NULL, 'yes', NULL, NULL, '8104183235'),
	('182f6be1-65f3-5289-bde1-7833f1f17a71', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'worker', 'Prince Edibamode', '8077957414', NULL, '0021', '2026-04-07', false, '2026-04-07 21:30:57.681195', '2026-12-24', 'Business Man', '35 Agip RD PH', 'princeedibamode@wisdompowercc.org', NULL, 'Edibamode', 'Prince', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, '35 Agip RD PH', NULL, NULL, 'Yes', NULL, NULL, '8054019647'),
	('4668c1ea-b2f0-51fa-a4d1-41096c6792f7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Zoe Ogor Godwin', '9054797669', NULL, '0047', '2026-04-07', false, '2026-04-07 21:40:51.818135', '2026-05-04', 'Student', 'Road 4 Plot 11 Agip Estate', 'zoegodwino@gmail.com', NULL, 'Ogor Godwin', 'Zoe', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 4 Plot 11 Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '7038613565'),
	('d06a4ea7-0373-5cdf-9f4a-b66cc0f9c6f1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Kaleglia I Mercy', '8036661197', NULL, '0119', '2026-04-08', false, '2026-04-08 07:24:14.266395', '2026-11-21', 'Business', 'Road 4', 'mercykaleglia@gmail.com', NULL, 'I Mercy', 'Kaleglia', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 4', NULL, NULL, 'yes', NULL, NULL, '9115636627'),
	('836e1d11-b1fd-5c86-8f52-e25973dc0712', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Victor Patience', '7065457935', NULL, '0049', '2017-05-01', false, '2026-04-07 21:30:57.681195', '2026-06-10', 'Business', '229 Mile 4,civic centre', 'patiencevictor18@gmail.com', NULL, 'Patience', 'Victor', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, '229 Mile 4,civic centre', NULL, NULL, 'yes', NULL, NULL, '8080992296'),
	('55c2775d-2e55-58a1-a6f5-2d036208cab3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Elizabeth Joseph Akidy', NULL, NULL, '0125', '2026-04-08', false, '2026-04-08 07:24:14.266395', '2026-11-21', 'Student', 'Road 6', 'elizabethjosephakidy@wisdompowercc.org', NULL, 'Joseph Akidy', 'Elizabeth', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 6', NULL, NULL, 'yes', NULL, NULL, '8055063012'),
	('a70f0fe0-2a30-5868-a046-00ebc1843f64', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Grace Sukuye', '8117199258', NULL, '0041', '1905-07-04', false, '2026-04-07 21:30:57.681195', '2026-12-04', 'Student', 'Road 5 flat 3b', 'gracesukoye@gmail.com', NULL, 'Sukuye', 'Grace', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 5 flat 3b', NULL, NULL, 'Yes', NULL, NULL, '8038900266'),
	('6f5def03-569a-5095-9201-c2626d894e70', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Esther Chibuzu Edwin', '7014145501', NULL, '0122', '2026-04-08', false, '2026-04-08 07:24:14.266395', '2026-04-26', 'Trader', 'Agip mbgoushimini', 'chidinma321@gmail.com', NULL, 'Chibuzu Edwin', 'Esther', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Agip mbgoushimini', NULL, NULL, 'yes', NULL, NULL, '7014115501'),
	('85ea5802-7ba1-5ff9-a8ab-52f8f965c84d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Ogerejeko Pamela', '8109089870', NULL, '0055', '2026-04-07', false, '2026-04-07 21:30:57.681195', '2026-11-05', 'Employed', 'Chinda', 'orupamela@gmail.com', NULL, 'Pamela', 'Ogerejeko', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Chinda', NULL, NULL, 'Yes', NULL, NULL, NULL),
	('f8c18b92-e5e3-5b29-b7e8-9a7dbff338ae', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Idu Maudlyn', '8060936660', NULL, '0123', '2026-04-08', false, '2026-04-08 07:24:14.266395', '2026-11-23', 'Business', 'Road 11 Agip Estate', 'idu.maudlyn@yahoo.com', NULL, 'Maudlyn', 'Idu', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 11 Agip Estate', NULL, NULL, 'yes', NULL, NULL, NULL),
	('afce8e7b-e114-518b-a169-c2c1261554cd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Neriton Prefa Mirabel', '8169703054', NULL, '0132', '2026-04-08', false, '2026-04-08 07:27:32.215241', '2026-08-01', 'Student', 'NTA', 'mirabelneritonprefa@gmail.com', NULL, 'Prefa Mirabel', 'Neriton', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'NTA', NULL, NULL, 'yes', NULL, NULL, '8030891132'),
	('57bfc01d-8315-5cbe-9bf0-5d9fa4a34a5c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '49831aa5-ffbe-44f3-bc8f-6e639553474e', 'worker', 'Peggy Efe Enaibre', '8023255460', NULL, '0006', '2026-04-07', false, '2026-04-07 21:32:08.498107', '2026-08-20', 'Educationist', NULL, 'peggy.enaibre@gmail.com', NULL, 'Efe Enaibre', 'Peggy', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, NULL, NULL, NULL, 'Yes', NULL, NULL, '7082163996'),
	('62f487e2-453a-428c-91ba-66349cc82251', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '46c85893-3953-4337-84f9-edb1806b0669', 'globaladmin', 'Adeshina Gentry', '8064134853', 'Global Lead Pastor, Wisdom Power Christian Centre', '0001', '2026-05-01', true, '2026-05-01 04:34:13.150295', '2026-08-06', 'Pastor', NULL, 'shinaadewole@gmail.com', 'https://scontent.fiba2-3.fna.fbcdn.net/v/t39.30808-6/241991601_10220154718084302_7019413582117396726_n.jpg?_nc_cat=111&ccb=1-7&_nc_sid=1d70fc&_nc_eui2=AeFMxdMvTDGH-SDd4PB1_DdHF7O-vZAAp6YXs769kACnprRICpKLqh1f_ASDRcM4nkMLxvyYACDyJVCju4i_faHU&_nc_ohc=E3fzZqFpeAwQ7kNvwFGLfyy&_nc_oc=AdquoSmExSZXslM8x7V34D29Nn7cSAqtedKxvTFB5iN4apdmu_FAS_7en_B9Uaj3-vQ&_nc_zt=23&_nc_ht=scontent.fiba2-3.fna&_nc_gid=xLZeWkVZqB3AlpSTK60Ehg&_nc_ss=7b2a8&oh=00_Af6woEBvmME1ij3ftdV1vqFVrGLkjgTE5YsWFMG89AnDPg&oe=69FA08E8', 'Adeshina ', 'Gentry', true, 'WPCC/HQ/', '2026-08-06', 'm', 'married', '234 806 413 4853', NULL, '2026-05-01', '2026-05-01', NULL, NULL, NULL, NULL),
	('eee782a8-5009-5a7b-bff6-0be616e4b2f7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Ikechukwu Hope Isaac', '8088646081', NULL, '0138', '2026-04-08', false, '2026-04-08 07:30:40.200729', '2026-09-28', 'Business', 'Orazi Mile 4', 'hopeikechukwu7@gmail.com', NULL, 'Hope Isaac', 'Ikechukwu', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Orazi Mile 4', NULL, NULL, 'Yes', NULL, NULL, '9027119800'),
	('f585dde3-a79e-50c3-9aad-4c9f321f00b0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '02d644fe-acd7-416f-aba1-6c9ccf4a7904', 'worker', 'Daniel Ademu', '8033342831', NULL, '0007', '2006-03-01', false, '2026-04-07 21:32:08.498107', '2026-07-04', 'Clegy', 'RD 4 Plot 11 Agip Estate', 'aookpanachi@yahoo.com', NULL, 'Ademu', 'Daniel', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, 'RD 4 Plot 11 Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '8134488388'),
	('19197c6e-2404-53f2-b618-026745017abc', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Otoware Elizabeth', '7031391896', NULL, '0139', '2026-04-08', false, '2026-04-08 07:30:40.200729', '2026-07-28', 'Online business', 'Extension A Agip Estate', 'babayeena66@gmail.com', NULL, 'Elizabeth', 'Otoware', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Extension A Agip Estate', NULL, NULL, 'yes', NULL, NULL, NULL),
	('f7894dcb-2794-5a0d-9e0b-0f640efbf80c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '46c85893-3953-4337-84f9-edb1806b0669', 'worker', 'Victor Chilvers', '8064810667', NULL, '0009', '2026-04-07', false, '2026-04-07 21:32:08.498107', '2026-12-13', 'Clergy', 'Yenegoa', 'victorschilvers@gmail.com', NULL, 'Chilvers', 'Victor', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, 'Yenegoa', NULL, NULL, 'Yes', NULL, NULL, '9060731283'),
	('74b41b31-0adc-59b8-9693-4683560913fd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e14a403b-9739-45ef-8a24-b90866749318', 'worker', 'Maris Agabi', '7067422153', NULL, '0034', '2026-04-07', false, '2026-04-07 21:32:39.050584', '2026-12-25', 'Workrer', '3 Elder Martins Agip Estate', 'marislifted@yahoo.com', NULL, 'Agabi', 'Maris', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, '3 Elder Martins Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '9139973637'),
	('0ef80e26-1f47-52a8-882e-660f3036ccc2', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2ddfe8b3-72c7-49d6-9450-588ce6d72ed3', 'worker', 'Iyingi Divine Sukuye', '8038900266', NULL, '0010', '2026-04-07', false, '2026-04-07 21:32:39.050584', '2026-06-18', 'Civil Servant', 'Road 5 flat3b Agip Estate', 'sukuinyingi@gmail.com', NULL, 'Divine Sukuye', 'Iyingi', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Road 5 flat3b Agip Estate', NULL, NULL, 'Yes', NULL, NULL, NULL),
	('344aa4cd-5f9c-5288-819b-3b9ae2095af7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Oluwapelumi Ibitoye', '9093750964', NULL, '0012', '2026-04-07', false, '2026-04-07 21:32:39.050584', '2026-01-07', NULL, 'Road 3 6b Agip Estate', 'oluwapelumiibitoye20@gmail.com', NULL, 'Ibitoye', 'Oluwapelumi', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Road 3 6b Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '8035337592'),
	('620ec5dd-b6f7-57a2-b08e-dbd81ece9ce1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Emmanuel Chukwueke', '7012110617.0', NULL, '0065-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Student', NULL, 'emmanuelchukwueke@wisdompowercc.org', NULL, 'Chukwueke', 'Emmanuel', false, 'WPCC/HQ/', '2026-12-28', 'M', 'Single', NULL, NULL, NULL, NULL, 'Yes', 'Yes', 'Yes', '8036771080'),
	('d510924a-5e33-5f69-be69-0982dfe7f0e7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'worker', 'Sunny Johnny', '7038804592.0', NULL, '0016', '2025-01-01', false, '2026-04-08 09:55:26.899423', NULL, NULL, NULL, 'sunnyjohnny247@gmail.com', NULL, 'Johnny', 'Sunny', false, 'WPCC/HQ/', '2026-06-22', 'M', 'Married', NULL, 'Obama Estate Rumu', NULL, NULL, 'Yes', 'Yes', 'Yes', NULL),
	('73014d1d-2851-54b1-a706-f1ee6868d407', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Gift Charles', '8060152337.0', NULL, '0063-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Chef', NULL, 'giftromans/50@gmail.com', NULL, 'Charles', 'Gift', false, 'WPCC/HQ/', '2026-03-09', 'F', 'Married', NULL, 'No 6 Amen Close', NULL, NULL, 'Yes', 'YES', 'Yes', '7060497206'),
	('16fa675d-23c2-5e11-9fb2-33e0f5eccfdc', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Balogun Ayomide', '8142774114.0', NULL, '0064', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Fashion Designer', NULL, 'balogunstouch@gmail.com', NULL, 'Ayomide', 'Balogun', false, 'WPCC/HQ/', '2026-04-05', 'M', 'Married', NULL, 'No 5 Ibomowei extension B', NULL, NULL, 'Yes', 'Yes', 'Yes', '8143774114'),
	('c5ae808b-48b6-5575-b032-4983f9d1751c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Joshua Lawrence', '7037716689.0', NULL, '0065-2', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Business', NULL, 'joshbla2027@gmail.com', NULL, 'Lawrence', 'Joshua', false, 'WPCC/HQ/', '2026-01-27', 'M', 'Single', NULL, 'Road 6 Flat 2a Agip Estate', NULL, NULL, 'Yes', 'Yes', 'Yes', '8064311281'),
	('7edafbb8-d2b2-584e-be78-f1f5a17e2a22', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '777796f6-7ea3-4ceb-a95b-eafcf573bc9f', 'worker', 'Bright Bethel Pepple', '8164976820.0', NULL, '0066-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Military', NULL, 'pepplebright@gmail.com', NULL, 'Bethel Pepple', 'Bright', false, 'WPCC/HQ/', '2026-03-19', 'M', 'Single', NULL, 'Wide Choice Iwofe', NULL, NULL, 'Yes', 'Yes', 'Yes', '8144147344'),
	('cdd47eec-8545-5582-9658-6cf0d40ae0e1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Alalibo Ibifubara Favour Deinsobote', '9121955467.0', NULL, '0067-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Student', NULL, 'alalifavour11@gmail.com', NULL, 'Ibifubara Favour Deinsobote', 'Alalibo', false, 'WPCC/HQ/', '2026-04-21', 'F', 'Single', NULL, 'Road 11 Agip Estate', NULL, NULL, 'Yes', 'Yes', 'Yes', '8060936660'),
	('84f9c52e-1a16-57ea-8d62-7589c3e875cf', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'worker', 'Claude Ibiye Igbani', '8037092501.0', NULL, '0068-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Self Employed', NULL, 'cligbani@gmail.com', NULL, 'Ibiye Igbani', 'Claude', false, 'WPCC/HQ/', '2026-12-27', 'M', 'Married', NULL, 'Road 4 10bAgip Estate', NULL, NULL, 'Yes', 'Yes', 'Yes', '8037092501'),
	('11641715-8db0-50bb-b41f-2fc14aa7122d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'a4bb9e51-b105-43a9-801c-14dd4ad60c1d', 'worker', 'Chidinma Diribe', '8036208727', NULL, '0019', '2026-04-07', false, '2026-04-07 21:32:08.498107', '2026-06-09', 'Event planner', 'plot 133 road 18 Agip', 'chidinmadiribe@gmail.com', NULL, 'Diribe', 'Chidinma', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'plot 133 road 18 Agip', NULL, NULL, 'Yes', NULL, NULL, '803704580'),
	('7c3edc10-5798-5c10-86fa-a5205b724472', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', '0wabia Emmanuella Adaeze', '9066077623.0', NULL, '0069-1', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Teacher', NULL, 'princesscharles27@yahoo.com', NULL, 'Emmanuella Adaeze', '0wabia', false, 'WPCC/HQ/', '2026-06-27', 'F', 'Single', NULL, '2 Egbelu abink newlayout st John', NULL, NULL, 'Yes', 'Yes', 'Yes', '7034464749'),
	('46d0856e-9f34-56a5-b954-6246d3647b4c', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Ogunsuware Tamaramiebi Glory', '9022200981.0', NULL, '0070', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Student', NULL, 'ogunsuwaretamaramiebi22@gmail.com', NULL, 'Tamaramiebi Glory', 'Ogunsuware', false, 'WPCC/HQ/', '2026-05-04', 'F', 'Married', NULL, 'Aluu Uniport', NULL, NULL, 'Yes', 'Yes', 'Yes', '9066521218'),
	('7bc7082a-e83e-5127-9db1-be3962f53d9e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'worker', 'Godstime Horsefall', '9131913979', NULL, '0086', '2026-04-07', false, '2026-04-07 21:32:08.498107', '2026-06-07', 'Technician', 'Oroalawor 10 Agip', '001godstimehorsefall@gmail.com', NULL, 'Horsefall', 'Godstime', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, 'Oroalawor 10 Agip', NULL, NULL, NULL, NULL, NULL, NULL),
	('1f47e3e6-55d8-5012-bccb-109553f8a2a0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Chinedu Oge Mary', '8033090319', NULL, '0095', '2026-04-07', false, '2026-04-07 21:30:57.681195', '2026-06-21', 'Business', 'comisssion area', 'chineduogemary@wisdompowercc.org', NULL, 'Oge Mary', 'Chinedu', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'comisssion area', NULL, NULL, 'Yes', NULL, NULL, NULL),
	('0a87aff0-1493-580f-a263-03bc8a28fdac', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'JoshuaTamaraebikemiene Sophia', '9066521218.0', NULL, '0071', '2026-04-08', false, '2026-04-08 12:21:00.751664', NULL, 'Student', NULL, 'joshuasophia108@gmail.com', NULL, 'Sophia', 'JoshuaTamaraebikemiene', false, 'WPCC/HQ/', '2026-05-24', 'F', 'Single', NULL, 'Shepherd Villa Aluu', NULL, NULL, 'Yes', 'Yes', 'Yes', '8130004037'),
	('5528e385-375b-53db-baa4-fcde2f4f7206', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'worker', 'Igwe Elijah Isaiah', '8064047217', NULL, '0017', '2009-09-18', false, '2026-04-07 21:33:10.567939', '2026-04-15', 'Civil Servant', 'Extension B Agip estate', 'elijahigwe7@gmail.com', NULL, 'Elijah Isaiah', 'Igwe', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, 'Extension B Agip estate', NULL, NULL, 'Yes', NULL, NULL, NULL),
	('b0a90f0d-da25-5533-9e54-b61ca723e8e0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Ebitari Life Osaronwolu', '8037661640', NULL, '0018', '2026-04-07', false, '2026-04-07 21:33:10.567939', '2026-06-12', 'Bussiness', NULL, 'diaraeugere12@gmail.com', NULL, 'Life Osaronwolu', 'Ebitari', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, NULL, NULL, NULL, 'Yes', NULL, NULL, '8032661640'),
	('33689fc4-d9fb-5905-b41d-4aa3d6f28813', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Sukuye Dumo Joshua', '9039504111', NULL, '0038', '2026-04-07', false, '2026-04-07 21:33:10.567939', '2026-05-06', 'Student', 'Road 5 Plot 3b Agip Estate', 'sukuyejoshua@gmail.com', NULL, 'Dumo Joshua', 'Sukuye', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Road 5 Plot 3b Agip Estate', NULL, NULL, 'Yes', NULL, NULL, '8038900266'),
	('ae94c95c-a8e7-5546-a35d-053aa2cffed0', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Ashira OlisaErike Presley', '7072377702', NULL, '0085', '2000-03-01', false, '2026-04-08 07:18:17.835044', NULL, 'Accountant', '15 Amen Close', 'machenryzpresley@gmail.com', NULL, 'OlisaErike Presley', 'Ashira', false, 'WPCC/HQ/', NULL, 'M', 'Married', NULL, '15 Amen Close', NULL, NULL, 'Yes', NULL, NULL, NULL),
	('7bfbf62d-d417-5d06-abed-6c922b4c8827', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Igbani Claudia Ibiye', '7042110762', NULL, '0088', '2026-03-11', false, '2026-04-08 07:18:17.835044', NULL, 'Student', 'Road 4 Agip estate', 'ibiyeclaudiia@gmail.com', NULL, 'Claudia Ibiye', 'Igbani', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 4 Agip estate', NULL, NULL, 'yes', NULL, NULL, NULL),
	('41a8efe7-56d9-52da-9e48-48735d9d4fab', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'worker', 'Idu Daniel', '7071064522', NULL, '0089', '2026-04-08', false, '2026-04-08 07:18:17.835044', '2026-03-13', 'Student', 'Road 11 Agip Estate', 'danielidu2580@gmail.com', NULL, 'Daniel', 'Idu', false, 'WPCC/HQ/', NULL, 'M', 'Single', NULL, 'Road 11 Agip Estate', NULL, NULL, 'yes', NULL, NULL, NULL),
	('e1c3c4c8-b903-5f1c-9149-f171031f4252', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'worker', 'Anuliyo Juliet Ekwutsi', '8032627844', NULL, '0091', '2019-07-04', false, '2026-04-08 07:20:17.099342', NULL, 'Working', 'Mimkwu avenue, Extension b', 'anuliyojulietekwutsi@wisdompowercc.org', NULL, 'Juliet Ekwutsi', 'Anuliyo', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Mimkwu avenue, Extension b', NULL, NULL, 'yes', NULL, NULL, '8034835292'),
	('0affa6e3-51cd-5955-b7ac-720eb6a8bd99', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Njujima Rolins Ayomide', '9028694922', NULL, '0096', '2021-10-04', false, '2026-04-08 07:20:17.099342', '2026-03-11', 'Business woman', 'Agip Estate', 'ibrahimayomide333@gmail.com', NULL, 'Rolins Ayomide', 'Njujima', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'Agip Estate', NULL, NULL, 'yes', NULL, NULL, NULL),
	('2fe4c83f-97e0-5a73-a54d-79e056c795af', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Joe Benson Oka', '8027478494', NULL, '0101', '2026-04-08', false, '2026-04-08 07:20:17.099342', NULL, 'Welder', NULL, 'joebenson@gmail.com', NULL, 'Benson Oka', 'Joe', false, 'WPCC/HQ/', NULL, 'M', NULL, NULL, NULL, NULL, NULL, 'yes', NULL, NULL, NULL),
	('24f737eb-9001-46a9-89a8-11f8a75b43d7', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'dcea05e8-fc39-4851-935c-808643593c73', 'admin', ' ', '', '', NULL, '2026-03-04', false, '2026-03-04 11:13:06.294564', NULL, '', ', , , ', 'test1@testweb.com.ng', 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/24f737eb-9001-46a9-89a8-11f8a75b43d7.jpg', '', '', true, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('c93c9406-5404-4822-8749-62761ff285f2', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Deborah Amanze', '+2348012345678', 'Passionate about using visual arts to spread the gospel.', 'RE-00401', '2026-03-01', true, '2026-03-01 18:34:29.055484', NULL, 'Brand Designer', NULL, 'deborah.a@church.org', NULL, NULL, NULL, false, 'WPCC/RE/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('5a1d5b85-b39e-440e-a5f0-656b8097a165', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', 'bd5f7833-cd47-48c7-8334-2c403d2d4aa0', 'worker', 'Samuel Okon', '+2348098765432', 'Dedicated to building digital tools for the kingdom.', 'RE-00402', '2026-03-01', true, '2026-03-01 18:34:29.055484', NULL, 'Software Engineer', NULL, 'samuel.o@church.org', NULL, NULL, NULL, false, 'WPCC/RE/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('f3732027-f05a-423c-a51a-ca2bda86b2f2', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', NULL, 'worker', 'Angus Igbani', '08182581363', 'Good boy', NULL, '2026-03-04', false, '2026-03-04 06:45:04.138221', '1956-03-04', 'Dev', NULL, 'projectonline.official@gmail.com', 'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/f3732027-f05a-423c-a51a-ca2bda86b2f2/f3732027-f05a-423c-a51a-ca2bda86b2f2.jpg', 'Igbani', 'Angus', true, 'WPCC/RE/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('7078799d-6cde-449d-b202-2f09f1e28e33', '5a65519c-cf68-4977-9e44-fc3f206ec9fb', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'worker', 'christian eze', '3456776543234', 'guy', NULL, '2026-03-06', false, '2026-03-06 02:09:56.953325', NULL, NULL, NULL, 'christiangentry@gmail.com', NULL, 'eze', 'christian', false, 'WPCC/RE/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('2a1ea96f-02e1-598d-a7e1-0d023a520ef6', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'worker', 'Faith Presley', '8167704009', NULL, '0090', '2023-04-01', false, '2026-04-07 21:28:20.097017', '2026-08-11', 'Nurse', '16 Amih Close Agip PH', 'harcourtfaith13@email.com', NULL, 'Presley', 'Faith', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, '16 Amih Close Agip PH', NULL, NULL, 'yes', NULL, NULL, '8167704009'),
	('6c186f2c-94b9-5c34-bf35-9de4a83a4efd', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'worker', 'Emi Elfrida Godwin', '7038613565', NULL, '0013', '2024-10-01', false, '2026-04-07 21:28:20.097017', '2026-05-24', 'Public Servant', '26 Obagi GRA 1', 'emichukwudi@gmail.com', NULL, 'Elfrida Godwin', 'Emi', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, '26 Obagi GRA 1', NULL, NULL, 'yes', NULL, NULL, '8114319114'),
	('9ee0ff4f-80fc-5e45-aa1f-056c0b346008', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'worker', 'Igbani Bilha Claude', '9033846542', NULL, '0020', '2026-04-07', false, '2026-04-07 21:33:10.567939', '2026-07-22', NULL, 'Road 14, New RoadAda George', 'igbanib9@gmail.com', NULL, 'Bilha Claude', 'Igbani', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Road 14, New RoadAda George', NULL, NULL, NULL, NULL, NULL, NULL),
	('a65cf3a7-40b1-5bd1-92cc-a0f4db703ab6', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Jeremiah Sharon', '8061620534', NULL, '0049-1', '2026-04-07', false, '2026-04-07 21:40:51.818135', '2026-03-17', NULL, '22 Chief Thomas St Eagle Island', 'jeremiahsharon@wisdompowercc.org', NULL, 'Sharon', 'Jeremiah', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, '22 Chief Thomas St Eagle Island', NULL, NULL, NULL, NULL, NULL, '8034580273'),
	('6ca918ed-e773-52ae-9f82-6685d81f73bf', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'd94730d7-4ee6-4e40-83c4-573ffe0c6e1d', 'worker', 'Idowu Mufato', '8064341666', NULL, '0078', '2026-04-08', false, '2026-04-08 07:16:59.114499', '1980-04-04', 'Aluminium fabricator', 'Road 24 Extension b', 'hunter41d@gmail.com', NULL, 'Mufato', 'Idowu', false, 'WPCC/HQ/', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('0b153e44-0f42-5195-8754-2737ca5dc94b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '049bd00b-a053-4a36-9c22-415f477f172e', 'worker', 'Chinwendu Oge Rose Mary', '8033090319', NULL, '0095-1', '2026-04-08', false, '2026-04-08 07:20:17.099342', NULL, 'Business', 'comisssion area', 'chinwenduogerosemary@wisdompowercc.org', NULL, 'Oge Rose Mary', 'Chinwendu', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'comisssion area', NULL, NULL, 'yes', NULL, NULL, NULL),
	('15458965-71f0-5401-bcbb-be5916bcf63d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'worker', 'Uloma I Iheanmeli', '7067078118', NULL, '0105', '2026-04-08', false, '2026-04-08 07:21:47.544856', '2026-10-28', NULL, NULL, 'ulomaonioha2020@gmail.com', NULL, 'I Iheanmeli', 'Uloma', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	('87cbe629-a4c0-5935-bee6-32f17be82cea', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', 'e14a403b-9739-45ef-8a24-b90866749318', 'worker', 'Temitope Ologun Benstowe', '8033519259', NULL, '0097', '2014-04-01', false, '2026-04-08 07:20:17.099342', '2026-05-02', 'business', 'No 4 Chinda street', 'temitopebenstowe@gmail.com', NULL, 'Ologun Benstowe', 'Temitope', false, 'WPCC/HQ/', NULL, 'F', 'Married', NULL, 'No 4 Chinda street', NULL, NULL, 'yes', NULL, NULL, '8037048781'),
	('b4caed66-5496-53ce-b229-34c82e9a235b', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', NULL, 'worker', 'Oyewole Kehinde', '8056395419', NULL, '0093', '2026-04-08', false, '2026-04-08 07:30:40.200729', '2026-06-30', 'Hairstylist', 'Extension B Agip estate', 'kehindeoewole139@gmail.com', NULL, 'Kehinde', 'Oyewole', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Extension B Agip estate', NULL, NULL, 'yes', NULL, NULL, '8068848442'),
	('5c0fd8c2-6c72-5e5e-b2bc-782559bf1e7a', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'worker', 'Sarah Francis Minimah', '7068519221', NULL, '0136', '2026-04-08', false, '2026-04-08 07:30:40.200729', NULL, 'Self employed', 'Rd12 Flat 12A Agip', 'sarahfrancisminimah@wisdompowercc.org', NULL, 'Francis Minimah', 'Sarah', false, 'WPCC/HQ/', NULL, 'F', 'Single', NULL, 'Rd12 Flat 12A Agip', NULL, NULL, 'No', NULL, NULL, NULL);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."roles" ("memberid", "full_name", "roleid", "rolename") VALUES
	('f3732027-f05a-423c-a51a-ca2bda86b2f2', 'Angus Igbani', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('24f737eb-9001-46a9-89a8-11f8a75b43d7', 'Updae John', 'b8326342-51b6-42e1-a870-f66633340a8e', 'admin'),
	('7078799d-6cde-449d-b202-2f09f1e28e33', 'christian eze', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('c93c9406-5404-4822-8749-62761ff285f2', 'Deborah Amanze', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('62f487e2-453a-428c-91ba-66349cc82251', 'Adeshina Gentry', 'afac070f-64f5-4377-984a-de9b0903c2ce', 'globaladmin'),
	('2a1ea96f-02e1-598d-a7e1-0d023a520ef6', 'Faith Presley', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('6c186f2c-94b9-5c34-bf35-9de4a83a4efd', 'Emi Elfrida Godwin', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('90556612-dd95-54aa-b469-a9aeff809687', 'Kassin Hauwa Esther', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('4aed5d09-24fc-57e2-b763-1fb1d87e4cc3', 'Christain Eze', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('33e87363-203d-55b1-a607-8dca27a46eed', 'Afoloyan Helen', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('182f6be1-65f3-5289-bde1-7833f1f17a71', 'Prince Edibamode', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('836e1d11-b1fd-5c86-8f52-e25973dc0712', 'Victor Patience', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('a70f0fe0-2a30-5868-a046-00ebc1843f64', 'Grace Sukuye', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('85ea5802-7ba1-5ff9-a8ab-52f8f965c84d', 'Ogerejeko Pamela', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('1f47e3e6-55d8-5012-bccb-109553f8a2a0', 'Chinedu Oge Mary', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('11641715-8db0-50bb-b41f-2fc14aa7122d', 'Chidinma Diribe', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('d510924a-5e33-5f69-be69-0982dfe7f0e7', 'Sunny Johnny', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('620ec5dd-b6f7-57a2-b08e-dbd81ece9ce1', 'Emmanuel Chukwueke', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('73014d1d-2851-54b1-a706-f1ee6868d407', 'Gift Charles', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('16fa675d-23c2-5e11-9fb2-33e0f5eccfdc', 'Balogun Ayomide', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('c5ae808b-48b6-5575-b032-4983f9d1751c', 'Joshua Lawrence', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('7edafbb8-d2b2-584e-be78-f1f5a17e2a22', 'Bright Bethel Pepple', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('cdd47eec-8545-5582-9658-6cf0d40ae0e1', 'Alalibo Ibifubara Favour Deinsobote', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('84f9c52e-1a16-57ea-8d62-7589c3e875cf', 'Claude Ibiye Igbani', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('7c3edc10-5798-5c10-86fa-a5205b724472', '0wabia Emmanuella Adaeze', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('46d0856e-9f34-56a5-b954-6246d3647b4c', 'Ogunsuware Tamaramiebi Glory', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('0a87aff0-1493-580f-a263-03bc8a28fdac', 'JoshuaTamaraebikemiene Sophia', '3ad8d7fb-97ba-4ccd-af08-8e612c9b4a85', 'worker'),
	('33689fc4-d9fb-5905-b41d-4aa3d6f28813', 'Sukuye Dumo Joshua', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('9c13f991-e95c-5b4b-9c8c-b5aecd907a3a', 'Grace Seifegha Warri Ebi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('15458965-71f0-5401-bcbb-be5916bcf63d', 'Uloma I Iheanmeli', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('dc6f0db4-4c33-5a1f-9efd-456e0fecebf8', 'Favour Abbey', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('a00f4b5b-696e-5810-a7b1-1fe1d5303198', 'Hope Saturday Nuka', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('9bb5cc87-d189-5067-9947-93d95e4ae873', 'Esther Adaeze Michael', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('a1ab1dba-c790-5afe-89ae-2cab65f2f0c0', 'Siminialaiyim Flourish Apollos', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('7de1a2ec-cd94-5f4a-894c-5b663bf32a99', 'Joyce Okah', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('f837bd63-9f89-53b1-91a5-8e99446d1bf9', 'Omuku Patience', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('82af049e-1ab6-5599-8805-728b6d081f21', 'Peace Ajie', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('20d88ef5-cbf9-510b-aa82-eb06ba097b6a', 'Uchechi Godspower Godwin', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('5639f727-44f2-5177-ad54-8c8bb61864f1', 'Eboma Victory Ndu', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('6262453e-52b0-5844-8da8-00a6f477eb3b', 'Okofor Gladys .E.', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('db838aba-1c49-5517-90c7-0105342a392c', 'Unuafe Zue', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('27dfcf5e-5182-5882-9654-722a945eef50', 'Faith Reuben', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('93616239-014c-535e-9907-743cc3984e03', 'Chinonyerem Benson', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('0bd73ba6-01a2-51a7-897d-606ecb6ee2f3', 'Godgift Ajie', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('d88ebca9-5481-55ec-8930-b5ee10fd9d39', 'Esther Onyeche', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('fd46d9f0-567f-59ac-870a-289308fb0537', 'Eniye Ehighakwo', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('ee6e16f1-b774-5c48-bf9a-8489108e6be2', 'Idu Daniella Chizi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('fa4b9146-3e7d-5466-a2fb-0a3fb4f7634b', 'Moshood Aminat Fumilayo', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('4388937c-0663-5c19-9326-df1497aae772', 'Moshood Aisha O.', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('6ca918ed-e773-52ae-9f82-6685d81f73bf', 'Idowu Mufato', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('fcbded63-f969-5559-a25e-821a639be14c', 'Mukoro Kesiena Abraham', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('7cd5e1ec-3cce-5f92-876d-c8acdd30a0d3', 'Anodere Chalya', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('f82d951d-a444-4f4d-b63b-d342582afdcd', 'Igbani angus Claude', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('63625f49-e9fb-5571-80ab-b94a3044e8c5', 'Isaiah Awaji Moroiso Rejoice', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('cf80d0e1-b26b-536a-b4a0-b25bc83ac591', 'Emmanuel Johnson', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('114ab3f4-0f8c-5f01-be8b-ecc32729cf87', 'Nancy Azubuike', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('4668c1ea-b2f0-51fa-a4d1-41096c6792f7', 'Zoe Ogor Godwin', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('7bfbf62d-d417-5d06-abed-6c922b4c8827', 'Igbani Claudia Ibiye', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('7bc7082a-e83e-5127-9db1-be3962f53d9e', 'Godstime Horsefall', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('a65cf3a7-40b1-5bd1-92cc-a0f4db703ab6', 'Jeremiah Sharon', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('11e9782c-3d90-53df-a276-5809d8e22197', 'Balogun Yemisi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('6c400f3e-a082-5371-b4d6-1a924fd575f4', 'Bolawatife Moshood', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('ae94c95c-a8e7-5546-a35d-053aa2cffed0', 'Ashira OlisaErike Presley', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('41a8efe7-56d9-52da-9e48-48735d9d4fab', 'Idu Daniel', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('57bfc01d-8315-5cbe-9bf0-5d9fa4a34a5c', 'Peggy Efe Enaibre', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('f585dde3-a79e-50c3-9aad-4c9f321f00b0', 'Daniel Ademu', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('f7894dcb-2794-5a0d-9e0b-0f640efbf80c', 'Victor Chilvers', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('74b41b31-0adc-59b8-9693-4683560913fd', 'Maris Agabi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('0ef80e26-1f47-52a8-882e-660f3036ccc2', 'Iyingi Divine Sukuye', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('344aa4cd-5f9c-5288-819b-3b9ae2095af7', 'Oluwapelumi Ibitoye', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('2b98f83f-35a0-5dcc-b86f-7fa5ebe303f4', 'Ebi Uchenna K', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('5528e385-375b-53db-baa4-fcde2f4f7206', 'Igwe Elijah Isaiah', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('b0a90f0d-da25-5533-9e54-b61ca723e8e0', 'Ebitari Life Osaronwolu', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('9ee0ff4f-80fc-5e45-aa1f-056c0b346008', 'Igbani Bilha Claude', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('e1c3c4c8-b903-5f1c-9149-f171031f4252', 'Anuliyo Juliet Ekwutsi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('0b153e44-0f42-5195-8754-2737ca5dc94b', 'Chinwendu Oge Rose Mary', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('0affa6e3-51cd-5955-b7ac-720eb6a8bd99', 'Njujima Rolins Ayomide', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('87cbe629-a4c0-5935-bee6-32f17be82cea', 'Temitope Ologun Benstowe', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('2fe4c83f-97e0-5a73-a54d-79e056c795af', 'Joe Benson Oka', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', 'Glory Okon Johnny', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('c9a2840c-c6c6-5f77-8d83-515fc1f944dc', 'Siminialaiyim Conqueror Apollos', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('12dc39be-d1f0-5150-9162-8c5cd15a4f83', 'Bright Chidera Osayi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('4a9b8455-2e2c-5310-9ff0-d91fc1aabb05', 'Joseph Akidy Israel', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('46e9b6c8-991c-5c7b-8b2d-74597c54173e', 'Cyril Victor', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('d06a4ea7-0373-5cdf-9f4a-b66cc0f9c6f1', 'Kaleglia I Mercy', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('55c2775d-2e55-58a1-a6f5-2d036208cab3', 'Elizabeth Joseph Akidy', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('6f5def03-569a-5095-9201-c2626d894e70', 'Esther Chibuzu Edwin', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('f8c18b92-e5e3-5b29-b7e8-9a7dbff338ae', 'Idu Maudlyn', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('b8296b18-2881-56b0-8f8b-5da2a2c53e03', 'Juliet Akioya', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('fbd5d811-c3e5-59a1-b9a4-06bfb166dd7b', 'Idara Lawrence Tom Bob Manuel', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('d4bb3016-28da-5bda-8bf8-d5f3b49f5870', 'Daniella Neriton Prefa Zikere', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('d6354343-e7f2-5cb4-a4f1-e26cb99f1a30', 'Godsfavour iheanomachi', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('afce8e7b-e114-518b-a169-c2c1261554cd', 'Neriton Prefa Mirabel', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('eee782a8-5009-5a7b-bff6-0be616e4b2f7', 'Ikechukwu Hope Isaac', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('19197c6e-2404-53f2-b618-026745017abc', 'Otoware Elizabeth', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('b243ea46-f950-5c14-ab42-7c8dbc08fdf6', 'Queen Elizabeth James Akyee', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('b4caed66-5496-53ce-b229-34c82e9a235b', 'Oyewole Kehinde', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker'),
	('5c0fd8c2-6c72-5e5e-b2bc-782559bf1e7a', 'Sarah Francis Minimah', 'de391225-d832-4dd5-8979-fb754c54ca9f', 'worker');


--
-- Data for Name: profileverification; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: workers; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."workers" ("id", "user_id", "department_id", "branch_id", "created_at", "membershipcode") VALUES
	('74b41b31-0adc-59b8-9693-4683560913fd', '74b41b31-0adc-59b8-9693-4683560913fd', 'e14a403b-9739-45ef-8a24-b90866749318', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:39.050584', '0034'),
	('11641715-8db0-50bb-b41f-2fc14aa7122d', '11641715-8db0-50bb-b41f-2fc14aa7122d', 'a4bb9e51-b105-43a9-801c-14dd4ad60c1d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:08.498107', '0019'),
	('cf80d0e1-b26b-536a-b4a0-b25bc83ac591', 'cf80d0e1-b26b-536a-b4a0-b25bc83ac591', 'e14a403b-9739-45ef-8a24-b90866749318', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:40:51.818135', '0044'),
	('87cbe629-a4c0-5935-bee6-32f17be82cea', '87cbe629-a4c0-5935-bee6-32f17be82cea', 'e14a403b-9739-45ef-8a24-b90866749318', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:20:17.099342', '0097'),
	('9ee0ff4f-80fc-5e45-aa1f-056c0b346008', '9ee0ff4f-80fc-5e45-aa1f-056c0b346008', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:33:10.567939', '0020'),
	('6c186f2c-94b9-5c34-bf35-9de4a83a4efd', '6c186f2c-94b9-5c34-bf35-9de4a83a4efd', 'e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:28:20.097017', '0013'),
	('90556612-dd95-54aa-b469-a9aeff809687', '90556612-dd95-54aa-b469-a9aeff809687', NULL, 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:28:20.097017', '0052'),
	('a65cf3a7-40b1-5bd1-92cc-a0f4db703ab6', 'a65cf3a7-40b1-5bd1-92cc-a0f4db703ab6', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:40:51.818135', '0049-1'),
	('182f6be1-65f3-5289-bde1-7833f1f17a71', '182f6be1-65f3-5289-bde1-7833f1f17a71', 'e869118b-30e1-4bc1-9dbc-cf44b216a44f', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:30:57.681195', '0021'),
	('c93c9406-5404-4822-8749-62761ff285f2', 'c93c9406-5404-4822-8749-62761ff285f2', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-29 09:54:19.623815', '0'),
	('7bc7082a-e83e-5127-9db1-be3962f53d9e', '7bc7082a-e83e-5127-9db1-be3962f53d9e', NULL, 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:08.498107', '0086'),
	('57bfc01d-8315-5cbe-9bf0-5d9fa4a34a5c', '57bfc01d-8315-5cbe-9bf0-5d9fa4a34a5c', '49831aa5-ffbe-44f3-bc8f-6e639553474e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:08.498107', '0006'),
	('f7894dcb-2794-5a0d-9e0b-0f640efbf80c', 'f7894dcb-2794-5a0d-9e0b-0f640efbf80c', '46c85893-3953-4337-84f9-edb1806b0669', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:08.498107', '0009'),
	('0ef80e26-1f47-52a8-882e-660f3036ccc2', '0ef80e26-1f47-52a8-882e-660f3036ccc2', '2ddfe8b3-72c7-49d6-9450-588ce6d72ed3', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:39.050584', '0010'),
	('5528e385-375b-53db-baa4-fcde2f4f7206', '5528e385-375b-53db-baa4-fcde2f4f7206', '021b4b42-59ea-46dd-aca3-59863eab53d1', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:33:10.567939', '0017'),
	('33e87363-203d-55b1-a607-8dca27a46eed', '33e87363-203d-55b1-a607-8dca27a46eed', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:28:20.097017', '0040'),
	('a70f0fe0-2a30-5868-a046-00ebc1843f64', 'a70f0fe0-2a30-5868-a046-00ebc1843f64', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:30:57.681195', '0041'),
	('85ea5802-7ba1-5ff9-a8ab-52f8f965c84d', '85ea5802-7ba1-5ff9-a8ab-52f8f965c84d', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:30:57.681195', '0055'),
	('1f47e3e6-55d8-5012-bccb-109553f8a2a0', '1f47e3e6-55d8-5012-bccb-109553f8a2a0', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:30:57.681195', '0095'),
	('9c13f991-e95c-5b4b-9c8c-b5aecd907a3a', '9c13f991-e95c-5b4b-9c8c-b5aecd907a3a', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:33:10.567939', '0042'),
	('6ca918ed-e773-52ae-9f82-6685d81f73bf', '6ca918ed-e773-52ae-9f82-6685d81f73bf', 'd94730d7-4ee6-4e40-83c4-573ffe0c6e1d', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:16:59.114499', '0078'),
	('15458965-71f0-5401-bcbb-be5916bcf63d', '15458965-71f0-5401-bcbb-be5916bcf63d', NULL, 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:21:47.544856', '0105'),
	('fa4b9146-3e7d-5466-a2fb-0a3fb4f7634b', 'fa4b9146-3e7d-5466-a2fb-0a3fb4f7634b', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:16:59.114499', '0076'),
	('b4caed66-5496-53ce-b229-34c82e9a235b', 'b4caed66-5496-53ce-b229-34c82e9a235b', NULL, 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:30:40.200729', '0093'),
	('4388937c-0663-5c19-9326-df1497aae772', '4388937c-0663-5c19-9326-df1497aae772', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:16:59.114499', '0077'),
	('11e9782c-3d90-53df-a276-5809d8e22197', '11e9782c-3d90-53df-a276-5809d8e22197', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:18:17.835044', '0079'),
	('24f737eb-9001-46a9-89a8-11f8a75b43d7', '24f737eb-9001-46a9-89a8-11f8a75b43d7', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-03-08 20:28:31.922076', '0'),
	('0b153e44-0f42-5195-8754-2737ca5dc94b', '0b153e44-0f42-5195-8754-2737ca5dc94b', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:20:17.099342', '0095-1'),
	('0affa6e3-51cd-5955-b7ac-720eb6a8bd99', '0affa6e3-51cd-5955-b7ac-720eb6a8bd99', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:20:17.099342', '0096'),
	('55c2775d-2e55-58a1-a6f5-2d036208cab3', '55c2775d-2e55-58a1-a6f5-2d036208cab3', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:24:14.266395', '0125'),
	('f8c18b92-e5e3-5b29-b7e8-9a7dbff338ae', 'f8c18b92-e5e3-5b29-b7e8-9a7dbff338ae', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:24:14.266395', '0123'),
	('b8296b18-2881-56b0-8f8b-5da2a2c53e03', 'b8296b18-2881-56b0-8f8b-5da2a2c53e03', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:27:32.215241', '0124'),
	('fbd5d811-c3e5-59a1-b9a4-06bfb166dd7b', 'fbd5d811-c3e5-59a1-b9a4-06bfb166dd7b', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:27:32.215241', '0126'),
	('afce8e7b-e114-518b-a169-c2c1261554cd', 'afce8e7b-e114-518b-a169-c2c1261554cd', '049bd00b-a053-4a36-9c22-415f477f172e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:27:32.215241', '0132'),
	('4aed5d09-24fc-57e2-b763-1fb1d87e4cc3', '4aed5d09-24fc-57e2-b763-1fb1d87e4cc3', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:28:20.097017', '0107'),
	('33689fc4-d9fb-5905-b41d-4aa3d6f28813', '33689fc4-d9fb-5905-b41d-4aa3d6f28813', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:33:10.567939', '0038'),
	('4668c1ea-b2f0-51fa-a4d1-41096c6792f7', '4668c1ea-b2f0-51fa-a4d1-41096c6792f7', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:40:51.818135', '0047'),
	('a1ab1dba-c790-5afe-89ae-2cab65f2f0c0', 'a1ab1dba-c790-5afe-89ae-2cab65f2f0c0', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:01.573109', '0058'),
	('20d88ef5-cbf9-510b-aa82-eb06ba097b6a', '20d88ef5-cbf9-510b-aa82-eb06ba097b6a', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:33.60788', '0063'),
	('7bfbf62d-d417-5d06-abed-6c922b4c8827', '7bfbf62d-d417-5d06-abed-6c922b4c8827', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:18:17.835044', '0088'),
	('41a8efe7-56d9-52da-9e48-48735d9d4fab', '41a8efe7-56d9-52da-9e48-48735d9d4fab', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:18:17.835044', '0089'),
	('049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', '049ffb56-25f7-556b-bcd3-a1c14cf7ed4d', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:21:47.544856', '0106'),
	('12dc39be-d1f0-5150-9162-8c5cd15a4f83', '12dc39be-d1f0-5150-9162-8c5cd15a4f83', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:21:47.544856', '0111'),
	('4a9b8455-2e2c-5310-9ff0-d91fc1aabb05', '4a9b8455-2e2c-5310-9ff0-d91fc1aabb05', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:21:47.544856', '0112'),
	('46e9b6c8-991c-5c7b-8b2d-74597c54173e', '46e9b6c8-991c-5c7b-8b2d-74597c54173e', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:24:14.266395', '0115'),
	('d4bb3016-28da-5bda-8bf8-d5f3b49f5870', 'd4bb3016-28da-5bda-8bf8-d5f3b49f5870', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:27:32.215241', '0128'),
	('f82d951d-a444-4f4d-b63b-d342582afdcd', 'f82d951d-a444-4f4d-b63b-d342582afdcd', 'dcea05e8-fc39-4851-935c-808643593c73', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 08:11:23.082382', '0104'),
	('836e1d11-b1fd-5c86-8f52-e25973dc0712', '836e1d11-b1fd-5c86-8f52-e25973dc0712', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:30:57.681195', '0049'),
	('344aa4cd-5f9c-5288-819b-3b9ae2095af7', '344aa4cd-5f9c-5288-819b-3b9ae2095af7', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:39.050584', '0012'),
	('2b98f83f-35a0-5dcc-b86f-7fa5ebe303f4', '2b98f83f-35a0-5dcc-b86f-7fa5ebe303f4', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:39.050584', '0015'),
	('b0a90f0d-da25-5533-9e54-b61ca723e8e0', 'b0a90f0d-da25-5533-9e54-b61ca723e8e0', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:33:10.567939', '0018'),
	('dc6f0db4-4c33-5a1f-9efd-456e0fecebf8', 'dc6f0db4-4c33-5a1f-9efd-456e0fecebf8', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:01.573109', '0050'),
	('a00f4b5b-696e-5810-a7b1-1fe1d5303198', 'a00f4b5b-696e-5810-a7b1-1fe1d5303198', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:01.573109', '0051'),
	('fd46d9f0-567f-59ac-870a-289308fb0537', 'fd46d9f0-567f-59ac-870a-289308fb0537', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:16:59.114499', '0072'),
	('ae94c95c-a8e7-5546-a35d-053aa2cffed0', 'ae94c95c-a8e7-5546-a35d-053aa2cffed0', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:18:17.835044', '0085'),
	('2fe4c83f-97e0-5a73-a54d-79e056c795af', '2fe4c83f-97e0-5a73-a54d-79e056c795af', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:20:17.099342', '0101'),
	('c9a2840c-c6c6-5f77-8d83-515fc1f944dc', 'c9a2840c-c6c6-5f77-8d83-515fc1f944dc', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:21:47.544856', '0109'),
	('d06a4ea7-0373-5cdf-9f4a-b66cc0f9c6f1', 'd06a4ea7-0373-5cdf-9f4a-b66cc0f9c6f1', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:24:14.266395', '0119'),
	('eee782a8-5009-5a7b-bff6-0be616e4b2f7', 'eee782a8-5009-5a7b-bff6-0be616e4b2f7', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:30:40.200729', '0138'),
	('19197c6e-2404-53f2-b618-026745017abc', '19197c6e-2404-53f2-b618-026745017abc', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:30:40.200729', '0139'),
	('b243ea46-f950-5c14-ab42-7c8dbc08fdf6', 'b243ea46-f950-5c14-ab42-7c8dbc08fdf6', 'c4a5ac7e-100f-4b07-a56d-a567578ac6ed', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:30:40.200729', '0133'),
	('2a1ea96f-02e1-598d-a7e1-0d023a520ef6', '2a1ea96f-02e1-598d-a7e1-0d023a520ef6', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:28:20.097017', '0090'),
	('63625f49-e9fb-5571-80ab-b94a3044e8c5', '63625f49-e9fb-5571-80ab-b94a3044e8c5', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:40:51.818135', '0043'),
	('114ab3f4-0f8c-5f01-be8b-ecc32729cf87', '114ab3f4-0f8c-5f01-be8b-ecc32729cf87', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:40:51.818135', '0045'),
	('9bb5cc87-d189-5067-9947-93d95e4ae873', '9bb5cc87-d189-5067-9947-93d95e4ae873', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:01.573109', '0057'),
	('7de1a2ec-cd94-5f4a-894c-5b663bf32a99', '7de1a2ec-cd94-5f4a-894c-5b663bf32a99', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:01.573109', '0060'),
	('f837bd63-9f89-53b1-91a5-8e99446d1bf9', 'f837bd63-9f89-53b1-91a5-8e99446d1bf9', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:33.60788', '0061'),
	('82af049e-1ab6-5599-8805-728b6d081f21', '82af049e-1ab6-5599-8805-728b6d081f21', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:33.60788', '0062'),
	('5639f727-44f2-5177-ad54-8c8bb61864f1', '5639f727-44f2-5177-ad54-8c8bb61864f1', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:33.60788', '0054-1'),
	('6262453e-52b0-5844-8da8-00a6f477eb3b', '6262453e-52b0-5844-8da8-00a6f477eb3b', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:42:33.60788', '0056-1'),
	('db838aba-1c49-5517-90c7-0105342a392c', 'db838aba-1c49-5517-90c7-0105342a392c', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:43:04.328479', '0065'),
	('27dfcf5e-5182-5882-9654-722a945eef50', '27dfcf5e-5182-5882-9654-722a945eef50', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:43:04.328479', '0066'),
	('93616239-014c-535e-9907-743cc3984e03', '93616239-014c-535e-9907-743cc3984e03', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:43:04.328479', '0067'),
	('0bd73ba6-01a2-51a7-897d-606ecb6ee2f3', '0bd73ba6-01a2-51a7-897d-606ecb6ee2f3', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:43:04.328479', '0068'),
	('d88ebca9-5481-55ec-8930-b5ee10fd9d39', 'd88ebca9-5481-55ec-8930-b5ee10fd9d39', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:43:04.328479', '0069'),
	('6c400f3e-a082-5371-b4d6-1a924fd575f4', '6c400f3e-a082-5371-b4d6-1a924fd575f4', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:18:17.835044', '0082'),
	('6f5def03-569a-5095-9201-c2626d894e70', '6f5def03-569a-5095-9201-c2626d894e70', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:24:14.266395', '0122'),
	('7cd5e1ec-3cce-5f92-876d-c8acdd30a0d3', '7cd5e1ec-3cce-5f92-876d-c8acdd30a0d3', '252f56bd-5cf4-4270-b64f-0fc740220bd5', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 08:11:23.082382', '/HQ/'),
	('e1c3c4c8-b903-5f1c-9149-f171031f4252', 'e1c3c4c8-b903-5f1c-9149-f171031f4252', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:20:17.099342', '0091'),
	('d6354343-e7f2-5cb4-a4f1-e26cb99f1a30', 'd6354343-e7f2-5cb4-a4f1-e26cb99f1a30', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:27:32.215241', '0131'),
	('5c0fd8c2-6c72-5e5e-b2bc-782559bf1e7a', '5c0fd8c2-6c72-5e5e-b2bc-782559bf1e7a', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:30:40.200729', '0136'),
	('fcbded63-f969-5559-a25e-821a639be14c', 'fcbded63-f969-5559-a25e-821a639be14c', '8b7ebcad-820b-4035-b320-f1a49e7b1f64', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 08:11:23.082382', '0146'),
	('f585dde3-a79e-50c3-9aad-4c9f321f00b0', 'f585dde3-a79e-50c3-9aad-4c9f321f00b0', '02d644fe-acd7-416f-aba1-6c9ccf4a7904', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-07 21:32:08.498107', '0007'),
	('ee6e16f1-b774-5c48-bf9a-8489108e6be2', 'ee6e16f1-b774-5c48-bf9a-8489108e6be2', '23d94616-5401-45f5-94b8-c86584de853e', 'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53', '2026-04-08 07:16:59.114499', '0073');


--
-- PostgreSQL database dump complete
--

insert into public.leaders (
  id,
  user_id,
  department_id,
  branch_id,
  created_at,
  title_id,
  is_active,
  start_date,
  end_date
)
select
  seed.id,
  seed.user_id,
  seed.department_id,
  seed.branch_id,
  now(),
  lt.id,
  true,
  now(),
  null
from (
  values
    (
      '4fd7ba4b-b6eb-4c2d-a101-111111111111'::uuid,
      'a1ab1dba-c790-5afe-89ae-2cab65f2f0c0'::uuid,
      'dcea05e8-fc39-4851-935c-808643593c73'::uuid,
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53'::uuid,
      'hod'::text
    ),
    (
      '4fd7ba4b-b6eb-4c2d-a101-222222222222'::uuid,
      'c93c9406-5404-4822-8749-62761ff285f2'::uuid,
      '049bd00b-a053-4a36-9c22-415f477f172e'::uuid,
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53'::uuid,
      'pro'::text
    )
) as seed(id, user_id, department_id, branch_id, title_code)
join public.leadership_titles lt
  on lt.code = seed.title_code
join public.profiles p
  on p.id = seed.user_id
join public.branches b
  on b.id = seed.branch_id
join public.departments d
  on d.id = seed.department_id
on conflict (id) do nothing;

insert into public.global_admins (id, created_at, title_id, is_active, assigned_at)
select
  '62f487e2-453a-428c-91ba-66349cc82251'::uuid,
  now(),
  lt.id,
  true,
  now()
from public.leadership_titles lt
where lt.code = 'global_events'
on conflict do nothing;

insert into public.roles (
  memberid,
  full_name,
  roleid,
  rolename,
  scope_type,
  branch_id,
  department_id,
  is_primary,
  is_active,
  assigned_at
)
select
  '0ef80e26-1f47-52a8-882e-660f3036ccc2'::uuid,
  'Iyingi Divine Sukuye',
  rt.id,
  rt.rolename,
  'branch',
  'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53'::uuid,
  null,
  false,
  true,
  now()
from public.roletypes rt
where rt.rolename = 'Directorate'
  and not exists (
    select 1
    from public.roles r
    where r.memberid = '0ef80e26-1f47-52a8-882e-660f3036ccc2'::uuid
      and r.rolename = 'Directorate'
      and r.is_active = true
  );

update public.roles r
set
  branch_id = coalesce(w.branch_id, p.branch_id),
  department_id = coalesce(w.department_id, p.department_id),
  scope_type = case
    when r.rolename = 'globaladmin' then 'global'
    when r.rolename = 'dept_leader' then 'department'
    else 'branch'
  end,
  is_primary = coalesce(r.is_primary, true),
  is_active = coalesce(r.is_active, true),
  assigned_at = coalesce(r.assigned_at, now())
from public.profiles p
left join public.workers w
  on w.user_id = p.id
where p.id = r.memberid;

select public.sync_dept_leader_role_for_user('a1ab1dba-c790-5afe-89ae-2cab65f2f0c0'::uuid);
select public.sync_dept_leader_role_for_user('c93c9406-5404-4822-8749-62761ff285f2'::uuid);
select public.sync_global_admin_role_for_user('62f487e2-453a-428c-91ba-66349cc82251'::uuid);

insert into public.departmental_recurring_events (
  id,
  title,
  description,
  recurrence_type,
  day_of_week,
  week_of_month,
  day_of_month,
  month,
  start_time,
  end_time,
  featured_url,
  branch_id,
  department_id,
  is_active,
  created_by,
  created_at,
  updated_at
)
values
  (
    '2d2084ee-7d8d-4e61-807d-111111111111',
    'Media Prayer Huddle',
    'Weekly recurring prayer huddle for the media department.',
    'weekly',
    2,
    null,
    null,
    null,
    '18:00:00',
    '19:00:00',
    'https://images.unsplash.com/photo-1515169067868-5387ec356754',
    'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
    'dcea05e8-fc39-4851-935c-808643593c73',
    true,
    'seed.sql',
    now(),
    now()
  ),
  (
    '2d2084ee-7d8d-4e61-807d-222222222222',
    'ICARE Training Circle',
    'Recurring training session for the ICARE department.',
    'weekly',
    4,
    null,
    null,
    null,
    '17:30:00',
    '18:30:00',
    'https://images.unsplash.com/photo-1517048676732-d65bc937f952',
    'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
    '049bd00b-a053-4a36-9c22-415f477f172e',
    true,
    'seed.sql',
    now(),
    now()
  )
on conflict (id) do nothing;

insert into public.announcements (
  id,
  title,
  content,
  scope,
  branch_id,
  department_id,
  created_by,
  created_at,
  mediaurl,
  hasmedia
)
select
  seed.id::uuid,
  seed.title,
  seed.content,
  seed.scope,
  seed.branch_id::uuid,
  seed.department_id::uuid,
  seed.created_by::uuid,
  seed.created_at::timestamp,
  seed.mediaurl,
  seed.hasmedia
from (
  values
    (
      '2f8dc8d3-4b98-489d-8f1a-1d1b2cbf5151',
      'Choir rehearsal moved',
      'Music team meets at 6:30pm in Hall B after the livestream checks.',
      'department',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      null,
      '2026-07-02 08:10:00',
      null,
      false
    ),
    (
      '15fbd491-8828-4eb2-b31f-a1de7816b44d',
      'Livestream team briefing',
      'Pre-service huddle starts 20 minutes early at the media control room.',
      'department',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      null,
      '2026-07-02 08:05:00',
      null,
      false
    ),
    (
      '948de179-0449-4618-b0e1-45a203b73fe3',
      'Sunday volunteers call',
      'All workers should be seated by 8:15am before the Sunday service broadcast opens.',
      'global',
      null,
      null,
      null,
      '2026-07-02 07:55:00',
      null,
      false
    )
) as seed (
  id,
  title,
  content,
  scope,
  branch_id,
  department_id,
  created_by,
  created_at,
  mediaurl,
  hasmedia
)
where
  seed.scope = 'global'
  or (
    seed.scope = 'department'
    and exists (
      select 1
      from public.branches b
      where b.id = seed.branch_id::uuid
    )
    and exists (
      select 1
      from public.departments d
      where d.id = seed.department_id::uuid
    )
  )
on conflict (id) do update
set
  title = excluded.title,
  content = excluded.content,
  scope = excluded.scope,
  branch_id = excluded.branch_id,
  department_id = excluded.department_id,
  created_by = excluded.created_by,
  created_at = excluded.created_at,
  mediaurl = excluded.mediaurl,
  hasmedia = excluded.hasmedia;

insert into public.departmental_events (
  id,
  title,
  description,
  branch_id,
  department_id,
  event_start_at,
  event_end_at,
  featured_url,
  location,
  latitude,
  longitude,
  is_active,
  created_by,
  created_at,
  updated_at
)
select
  seed.id::uuid,
  seed.title,
  seed.description,
  seed.branch_id::uuid,
  seed.department_id::uuid,
  seed.event_start_at::timestamptz,
  seed.event_end_at::timestamptz,
  seed.featured_url,
  seed.location,
  seed.latitude::double precision,
  seed.longitude::double precision,
  seed.is_active,
  seed.created_by,
  seed.created_at::timestamp,
  seed.updated_at::timestamp
from (
  values
    (
      '0ed62025-915a-4bcc-aad3-5e52f1cad16b',
      'Imminent Major Breakthrough in Glory',
      'Media and technical workers finalise the service rundown, lower thirds, and opening broadcast flow.',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      '2026-07-02 17:00:00+00',
      '2026-07-02 19:00:00+00',
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776286901899_scaled_659626174_18368307715204822_2743028741766509114_n.jpg',
      'Main Auditorium',
      null,
      null,
      true,
      'home_feed_seed',
      now(),
      now()
    ),
    (
      '8689171b-919f-40bd-b21c-f3dd4d4304d4',
      'Glory Night',
      'Saturday praise and livestream capture set for the media and technical department.',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      '2026-07-04 18:00:00+00',
      '2026-07-04 20:00:00+00',
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776287000713_scaled_656837334_18367733518204822_6430428026206091633_n.jpg',
      'Youth Church Hall',
      null,
      null,
      true,
      'home_feed_seed',
      now(),
      now()
    ),
    (
      '5c3f5480-b11b-4a89-8edb-bb91915a90f0',
      'Youth Praise Party',
      'Creative projection, camera teams, and audio operators support the youth praise gathering.',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      '2026-07-05 15:00:00+00',
      '2026-07-05 17:00:00+00',
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776287000713_scaled_656837334_18367733518204822_6430428026206091633_n.jpg',
      'Teen Church Auditorium',
      null,
      null,
      true,
      'home_feed_seed',
      now(),
      now()
    ),
    (
      '8f536d46-f3ae-49a8-8802-a935e65f499d',
      'Livestream Audio Check',
      'Hands-on training for audio balance, backup recording, and monitor mixes before midweek service.',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      '2026-07-09 16:00:00+00',
      '2026-07-09 17:15:00+00',
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776286901899_scaled_659626174_18368307715204822_2743028741766509114_n.jpg',
      'Media Control Room',
      null,
      null,
      true,
      'home_feed_seed',
      now(),
      now()
    ),
    (
      '22a3fc39-28d3-4793-b455-43423f94eead',
      'Media Volunteers Huddle',
      'Departmental huddle for camera placement, graphics timing, and projection readiness.',
      'f20d9454-5ceb-4d49-a9d7-a608bfb2bb53',
      'dcea05e8-fc39-4851-935c-808643593c73',
      '2026-07-11 14:00:00+00',
      '2026-07-11 15:00:00+00',
      'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776286901899_scaled_659626174_18368307715204822_2743028741766509114_n.jpg',
      'Hall B',
      null,
      null,
      true,
      'home_feed_seed',
      now(),
      now()
    )
) as seed (
  id,
  title,
  description,
  branch_id,
  department_id,
  event_start_at,
  event_end_at,
  featured_url,
  location,
  latitude,
  longitude,
  is_active,
  created_by,
  created_at,
  updated_at
)
where exists (
  select 1
  from public.branches b
  where b.id = seed.branch_id::uuid
)
and exists (
  select 1
  from public.departments d
  where d.id = seed.department_id::uuid
)
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  branch_id = excluded.branch_id,
  department_id = excluded.department_id,
  event_start_at = excluded.event_start_at,
  event_end_at = excluded.event_end_at,
  featured_url = excluded.featured_url,
  location = excluded.location,
  is_active = excluded.is_active,
  created_by = excluded.created_by,
  updated_at = now();

insert into public.global_recurring_events (
  id,
  title,
  description,
  recurrence_type,
  day_of_week,
  week_of_month,
  day_of_month,
  month,
  start_time,
  end_time,
  featured_url,
  is_active,
  created_by,
  created_at,
  updated_at
)
values
  (
    '497bb722-a246-49f7-9f5b-f9d43b4db7b5',
    'Sunday Worship Celebration',
    'Church-wide Sunday worship service for all members in Africa/Lagos.',
    'weekly',
    0,
    null,
    null,
    null,
    '09:00:00',
    '11:30:00',
    'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776286901899_scaled_659626174_18368307715204822_2743028741766509114_n.jpg',
    true,
    'home_feed_seed',
    now(),
    now()
  ),
  (
    '33fdb8af-7783-4d24-90f2-9a9d45da5f64',
    'Thursday Midweek Service',
    'Church-wide Thursday midweek service for teaching, prayer, and communion.',
    'weekly',
    4,
    null,
    null,
    null,
    '17:30:00',
    '20:00:00',
    'https://pub-ad39479f015849b38cbe74e76712d1e4.r2.dev/pfp/24f737eb-9001-46a9-89a8-11f8a75b43d7/1776287000713_scaled_656837334_18367733518204822_6430428026206091633_n.jpg',
    true,
    'home_feed_seed',
    now(),
    now()
  )
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  recurrence_type = excluded.recurrence_type,
  day_of_week = excluded.day_of_week,
  week_of_month = excluded.week_of_month,
  day_of_month = excluded.day_of_month,
  month = excluded.month,
  start_time = excluded.start_time,
  end_time = excluded.end_time,
  featured_url = excluded.featured_url,
  is_active = excluded.is_active,
  created_by = excluded.created_by,
  updated_at = now();


-- Binary assets are stored in Cloudflare R2, so local database seeding does
-- not create or update Supabase Storage buckets.

-- \unrestrict xMXcD7pZx49r4P1qaLhXcEqeCWRYCFbJKiTgYPV3xMtEeZypxPGzJ2YgBVW4rcc

select public.backfill_seed_auth_users();

RESET ALL;
