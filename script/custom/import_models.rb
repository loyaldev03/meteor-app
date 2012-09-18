# 1- Get access to phoenix, billing_component, customer_services and prospect databases
# UPDATE billing_component.members set imported_at = NULL where imported_at IS NOT NULL
# UPDATE notes set imported_at = NULL where imported_at IS NOT NULL
# UPDATE operations set imported_at = NULL where imported_at IS NOT NULL
# 2- Import new prospects into phoenix
#     ruby script/custom/import_prospects.rb  
# 3- Update members already imported and Load new members 
#     ruby script/custom/import_members.rb  
# 4- Import operations.
#     ruby script/custom/import_operations.rb  
# 5- Import member notes.
#     ruby script/custom/import_member_notes.rb  
# 6- Import transactions.
#     ruby script/custom/import_transactions.rb  
#
#
# 3- set campaign_id on every membership authorization, to get the amount. 
#   UPDATE onmc_billing.membership_authorizations SET campaign_id = 
#      (SELECT campaign_id FROM onmc_billing.members WHERE id =  onmc_billing.membership_authorizations.member_id) WHERE
#       onmc_billing.membership_authorizations campaign_id IS NULL;

require 'rubygems'
require 'rails'
require 'active_record'
require 'uuidtools'
require 'attr_encrypted'
require 'settingslogic'

CLUB = 1 # ONMC
DEFAULT_CREATED_BY = 1 # batch
PAYMENT_GW_CONFIGURATION_LITLE = 2 
PAYMENT_GW_CONFIGURATION_MES = 3
TEST = false # if true email will be replaced with a fake one
USE_PROD_DB = true
SITE_ID = 2010001547 # lyris site id
MEMBER_GROUP_TYPE = 4 # MemberGroupType.new :club_id => CLUB, :name => "Chapters"
TIMEZONE = 'Eastern Time (US & Canada)'

CREDIT_CARD_NULL = "0000000000"
USE_MEMBER_LIST = true

@cids = %w(
1797
1798
1799
1800
1801
1802
1804
1805
1806
1807
1808
1809
1812
1813
1814
1815
1816
1817
1818
1819
1820
1821
1822
1823
1824
1825
1826
1827
1828
1829
1830
1831
1832
1833
1834
1835
1836
1837
1838
1839
1840
1841
1842
1843
1844
1845
1846
1847
1848
1849
1850
1852
1853
1854
1855
1856
1857
1858
1859
1860
1861
1862
1863
1864
1865
1866
1867
1868
1869
1870
69
70
71
72
73
74
75
76
77
78
79
80
81
82
83
84
85
86
87
88
89
90
91
92
93
94
95
96
97
98
99
100
101
102
103
104
105
106
107
108
109
110
111
112
113
114
115
116
117
118
119
120
121
122
123
124
125
126
127
128
129
130
131
132
133
134
135
136
137
138
139
140
141
142
143
144
145
146
147
148
149
150
151
152
153
154
155
156
157
158
159
160
161
162
163
164
165
166
167
168
169
170
171
172
173
174
175
176
177
178
179
180
181
182
183
184
185
186
187
188
189
190
191
192
193
194
195
196
197
198
199
200
201
202
203
204
205
206
207
208
209
210
211
212
213
214
215
216
217
218
219
220
221
222
223
224
225
226
227
228
229
230
231
249
250
251
252
253
254
255
1871
1872
1873
1874
1875
1876
1877
1878
1879
1880
1881
1882
1883
1884
1885
1886
1887
1888
1889
1890
1891
1892
1893
1894
1895
1896
1897
1898
1899
1900
1901
1902
1903
1904
1905
1906
1907
1908
1909
1910
1783
1784
1785
1786
1787
1788
1789
1790
1791
1792
1793
1794
1795
1613
1614
1615
1616
1617
1618
1619
1620
1621
1622
1623
1624
1625
1626
1627
1628
1629
1630
1631
1632
1633
1634
1635
1636
1637
1638
1639
1640
1641
1642
1643
1644
1645
1646
1647
1648
1649
1650
1651
1652
1482
1483
1484
1485
1486
1487
1488
1489
1490
1491
1653
1654
1655
1656
1657
1658
1659
1660
1661
1662
1663
1664
1665
1666
1667
1668
1669
1670
1671
1672
1673
1674
1675
1676
1677
1678
1679
1680
190
225
10
14
15
16
19
20
21
23
26
28
29
31
32
33
34
38
39
40
41
42
43
44
45
46
47
48
49
50
51
52
53
54
55
56
1125
1126
1127
1128
1129
1130
1131
1132
1133
1134
1135
1136
1137
1138
1139
57
1348
1349
1350
1404
1405
1406
1407
1408
1409
1410
1411
1412
1413
1414
1415
1416
1417
1418
1419
1420
1421
1422
1423
1424
1425
1426
1427
1428
1429
1430
1431
1432
1433
1434
1435
1436
1437
1438
1439
1440
1441
1442
1443
1444
1445
1446
1447
1448
1449
1450
1451
1452
1453
1454
1455
1456
1457
1458
1459
1460
1461
1462
1463
1464
1465
1351
1352
1353
1354
1355
1356
1357
1358
1359
1360
1361
1362
1363
1364
1365
1366
1367
1368
1369
1370
1371
1372
1373
1374
1375
1376
1377
1378
1379
1109
1110
1111
1112
1113
1114
1115
1116
1117
1118
1119
1120
1121
1122
58
59
60
61
62
63
64
65
66
67
68
298
299
321
322
323
1123
1124
1141
1142
1143
1144
1145
1146
1147
1148
1149
1150
1151
1152
1153
1154
1155
1156
1157
1158
1159
1160
1169
1170
1140
1183
1184
1185
1186
1187
1188
1311
1312
1313
1394
1395
1396
1397
1400
1401
1402
1403
1466
1467
1468
1469
1548
1549
1550
1551
1552
1553
1554
1555
1556
1557
1558
1559
1560
1561
1562
1563
1564
1565
1566
1567
1568
1569
1570
1571
1572
1573
1574
1575
1576
1577
1578
1579
1580
1581
1582
1583
1584
1585
1586
1587
1588
1589
1590
1591
1592
1593
1594
1595
1596
1597
1598
1599
1600
1601
1602
1603
1604
1605
1606
1607
1677
1678

999

1221
1222
1223
1224
1225
1226
1227
1228
1229
1230
1231
1232
1233
1235
1236
1237
1238
1239
1234
1246
1247
1248
1249
1250
1251
1252
1253
1254
1256
1257
1258
1285
1286
1287
1288
1289
1290
1291
1292
1293

1294
1295
1296
1297
1298
1299
1300
1301
1302
1303
1304
1305
1306
1307
1308
1309
1310
1317
1318
1319
1320
1321
1322
1336
1337
1338
1339
1340
1341
1492
1493
1494
1495
1496
1497

1498
1499
1500
1501
1502
1503
1504
1505
1520
1521
1522
1523
1524
1525
1526
1323
1324
1325
1326
1327
1328
1329
1330
1331
1332
1333
1334
1335
1342
1343
1344
1345
1346
1347
1506
1507
1508
1509
1510
1511
1512
1513
1514
1515
1516
1517
1518
1519
1527
1528
1529
1530
1531
1532
1533
1018


888
1200
1698
1870
1034
1192
1202
1699
324
1002
1193
1203
2
261
262
263
264
265
266
267
268
269
270
271
272
273
274
275
276
277
278
279
280
281
282
283
284
285
1001
1003
1004
1201
1608
1609
1610
1611
1612
1206


1380
998
996
993
997
991
984
995
994
35
315
316
317
318
344
345
1000
990
992
3
4
5
340
342
343
346
347
348
349
350
351
1770
1771
1772
1773
1774
1775
1776
1777
1778
1779
1780
1781
1782
1204
1205
7
8
9
325
326
327
328
329
330
331
332
333
334
335
336
337
338
339
1010
1011
1012
1013
1014
1015

1016
1019
1020
1021
1022
1023
1024
1025
1026
1027
1028
1029
1030
1031
1032
1033
1035
1036
1037
1038
1039
1040
1041
1042
1043
1044
1045
1046
1047
1048
1049
1050
1051
1052
1053
1054
1055
1056
1057
1058
1059
1060
1061
1062
1063
1064
1065
1066
1067
1068
1069
1070
1071
1072
1073
1074
1075
1076
1077
1078
1079
1080
1081
1082
1083
1084
1085
1086
1087
1088
1089
1090
1091
1092
1093
1094
1095
1096
1097
1098
1099
1100
1101
1102
1103
1104
1105
1106
1107
1108
1165
1166
1167
1168
1171
1172
1173
1174
1175
1176
1177
1178
1179
1180
1181
1182
1208
1209
1210
1211
1212
1213
1214
1215
1216
1217
1218
1219
1220
1240
1241
1242
1243
1244
1245
1259
1260
1261
1262
1263
1264
1265
1266
1267
1268
1269
1270
1271
1272
1273
1274
1275
1276
1277
1278
1279
1280
1281
1282
1283
1284
1387
1388
1389
1390
1391
1392
1393
1398
1399

)


if USE_PROD_DB
#  puts "by default do not continue. Uncomment this line if you want to run script. \n\t check configuration above." 
#  exit
end

unless USE_PROD_DB
  ActiveRecord::Base.configurations["phoenix"] = { 
    :adapter => "mysql2",
    :database => "sac_platform_development",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }

  ActiveRecord::Base.configurations["billing"] = { 
    :adapter => "mysql2",
    :database => "onmc_billing",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }

  ActiveRecord::Base.configurations["customer_services"] = { 
    :adapter => "mysql2",
    :database => "onmc_customer_service",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }

  ActiveRecord::Base.configurations["prospect"] = { 
    :adapter => "mysql2",
    :database => "onmc_prospects",
    :host => "127.0.0.1",
    :username => "root",
    :password => "" 
  }
else
  # PRODUCTION !!!!!!!!!!!!!!!!
  ActiveRecord::Base.configurations["phoenix"] = { 
    :adapter => "mysql2",
    :database => "sac_production",
    :host => "10.6.0.58",
    :username => "root",
    :password => 'pH03n[xk1{{s', 
    :port => 3306 
  }

  ActiveRecord::Base.configurations["billing"] = { 
    :adapter => "mysql2",
    :database => "billingcomponent_production",
    :host => "10.6.0.6",
    :username => "root2",
    :password => "f4c0n911",
    :port => 3306
  }

  ActiveRecord::Base.configurations["customer_services"] = { 
    :adapter => "mysql2",
    :database => "customerservice3",
    :host => "10.6.0.6",
    :username => "root2",
    :password => "f4c0n911",
    :port => 3308
  }

  ActiveRecord::Base.configurations["prospect"] = { 
    :adapter => "mysql2",
    :database => "prospectcomponent",
    :host => "10.6.0.6",
    :username => "root2",
    :password => "f4c0n911",
    :port => 3306
  }
end


class ProspectProspect < ActiveRecord::Base
  establish_connection "prospect" 
  self.table_name = "prospects" 
  self.record_timestamps = false
  serialize :preferences, JSON
  serialize :referral_parameters, JSON

  def email_to_import
    TEST ? "test#{member.id}@xagax.com" : email
  end  
end

class PhoenixMember < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "members" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  serialize :preferences, JSON

  def self.cohort_formula(join_date, enrollment_info, time_zone, installment_type)
    [ join_date.to_time.in_time_zone(time_zone).year.to_s, 
      "%02d" % join_date.to_time.in_time_zone(time_zone).month.to_s, 
      enrollment_info.mega_channel.to_s.strip, 
      enrollment_info.campaign_medium.to_s.strip,
      installment_type ].join('-').downcase
  end 

  def phone_number=(phone)
    return nil if phone.nil?
    p = phone.gsub(/[\s~\(\/\-=\)"\_\.\[\]+]/, '')
    p = p.split('ext')[0] if p.split('ext').size == 2

    if p.size < 6 || p.include?('@') || !p.match(/^[a-z]/i).nil? || p.include?('SOAP::Mapping')
    elsif p.size == 7  || p.size == 8 || p.size == 6
      phone_country_code = '1'
      phone_local_number = p
    elsif p.size >= 20
      phone_country_code = '1'
      phone_area_code = p[0..2]
      phone_local_number = p[3..9]
    elsif p.size == 10 || p.size == 9
      phone_country_code = '1'
      phone_area_code = p[0..2]
      phone_local_number = p[3..-1]
    elsif p.size == 11
      phone_country_code = p[0..0]
      phone_area_code = p[1..3]
      phone_local_number = p[4..-1]
    elsif p.size == 12
      phone_country_code = p[0..1]
      phone_area_code = p[2..4]
      phone_local_number = p[5..-1]
    elsif p.size == 13
      phone_country_code = p[0..1]
      phone_area_code = p[2..5]
      phone_local_number = p[6..-1]
    else
      raise "Dont know how to parse -#{p}-"
    end
  end
end

class PhoenixProspect < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "prospects" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  serialize :preferences, JSON
  serialize :referral_parameters, JSON

# 3304940833ext412

  def phone_number=(phone)
    return nil if phone.nil?
    p = phone.gsub(/[\s~\(\/\-=\)"\_\.\[\]+]/, '')
    p = p.split('ext')[0] if p.split('ext').size == 2

    if p.size < 6 || p.include?('@') || !p.match(/^[a-z]/i).nil? || p.include?('SOAP::Mapping')
    elsif p.size == 7  || p.size == 8 || p.size == 6
      phone_country_code = '1'
      phone_local_number = p
    elsif p.size >= 20
      phone_country_code = '1'
      phone_area_code = p[0..2]
      phone_local_number = p[3..9]
    elsif p.size == 10 || p.size == 9
      phone_country_code = '1'
      phone_area_code = p[0..2]
      phone_local_number = p[3..-1]
    elsif p.size == 11
      phone_country_code = p[0..0]
      phone_area_code = p[1..3]
      phone_local_number = p[4..-1]
    elsif p.size == 12
      phone_country_code = p[0..1]
      phone_area_code = p[2..4]
      phone_local_number = p[5..-1]
    elsif p.size == 13
      phone_country_code = p[0..1]
      phone_area_code = p[2..5]
      phone_local_number = p[6..-1]
    elsif 
      num = p.split('ext')[0]
      phone_country_code = p[0..1]
      phone_area_code = p[2..5]
      phone_local_number = p[6..-1]
    else
      raise "Dont know how to parse -#{p}-"
    end
  end
end
class PhoenixCreditCard < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "credit_cards"
  attr_encrypted :number, :key => 'reibel3y5estrada8', :encode => true, :algorithm => 'bf' 
  before_create :update_last_digits
  def update_last_digits
    self.last_digits = self.number.last(4) 
  end  
end
class PhoenixOperation < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "operations" 
end
class PhoenixClubCashTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "club_cash_transactions" 
end
class PhoenixEnrollmentInfo < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "enrollment_infos" 
end
class PhoenixTransaction < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "transactions" 
  self.primary_key = 'uuid'
  before_create 'self.id = UUIDTools::UUID.random_create.to_s'

  def set_payment_gateway_configuration(gateway)
    if gateway == 'litle'
      pgc = PhoenixPGC.find(PAYMENT_GW_CONFIGURATION_LITLE)
    else
      pgc = PhoenixPGC.find(PAYMENT_GW_CONFIGURATION_MES)
    end
    self.payment_gateway_configuration_id = pgc.id
    self.report_group = pgc.report_group
    self.merchant_key = pgc.merchant_key
    self.login = pgc.login
    self.password = pgc.password
    self.mode = pgc.mode
    self.descriptor_name = pgc.descriptor_name
    self.descriptor_phone = pgc.descriptor_phone
    self.order_mark = pgc.order_mark
    self.gateway = pgc.gateway
  end  
end
class PhoenixPGC < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "payment_gateway_configurations" 
end
class PhoenixMemberNote < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "member_notes" 
end
class PhoenixEnumeration < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "enumerations" 
end
class DispositionType < PhoenixEnumeration
end
class CommunicationType < PhoenixEnumeration
end
class PhoenixAgent < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "agents" 
end
class PhoenixFulfillment < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "fulfillments"
end
class PhoenixTermsOfMembership < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "terms_of_memberships" 
end
class PhoenixEmailTemplate < ActiveRecord::Base
  establish_connection "phoenix" 
  self.table_name = "email_templates" 
end


class Settings < Settingslogic
  source "application.yml"
  namespace Rails.env
end




class BillingMember < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "members"
  self.record_timestamps = false

  def email_to_import
    TEST ? "test#{member.id}@xagax.com" : email
  end
end
class BillingCampaign < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "campaigns" 
  self.record_timestamps = false
  def is_joint
    joint == 'n' ? false : true
  end
end
class BillingEnrollmentAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_auth_responses" 
  self.record_timestamps = false
  def phoenix_gateway
    gateway == 'mes' ? gateway : 'litle'
  end
  def authorization
    BillingEnrollmentAuthorization.find_by_id(self.authorization_id)
  end
  def invoice_number(a)
    "#{self.created_at.to_date}-#{a.member_id}"
  end
  def member
    PhoenixMember.find_by_visible_id_and_club_id(authorization.member_id, CLUB)
  end
  def capture
    if authorization.litleTxnId.to_s.size > 2
     BillingEnrollmentCapture.find_by_member_id_and_litleTxnId(authorization.member_id, authorization.litleTxnId)
    else
     nil
    end
  end
  def capture_response
    capture.nil? ? nil : BillingEnrollmentCaptureResponse.find_by_capture_id(capture.id)
  end
  def amount
    phoenix_amount
  end
end
class BillingEnrollmentAuthorization < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_authorizations" 
  self.record_timestamps = false
end
class BillingEnrollmentCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_captures" 
  self.record_timestamps = false
end
class BillingEnrollmentCaptureResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "enrollment_capt_responses" 
  self.record_timestamps = false
end
class BillingMembershipAuthorizationResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_auth_responses" 
  self.record_timestamps = false
  def phoenix_gateway
    gateway == 'mes' ? gateway : 'litle'
  end
  def authorization
    BillingMembershipAuthorization.find_by_id(self.authorization_id)
  end
  def member
    PhoenixMember.find_by_visible_id_and_club_id(authorization.member_id, CLUB)
  end
  def billing_member
    BillingMember.find_by_id(authorization.member_id)
  end
  def capture
    if authorization.litleTxnId.to_s.size > 2
      BillingMembershipCapture.find_by_member_id_and_litleTxnId(authorization.member_id, authorization.litleTxnId)
    else
      nil
    end
  end
  def invoice_number(a)
    "#{self.created_at.to_date}-#{a.member_id}"
  end
  def capture_response
    capture.nil? ? nil : BillingMembershipCaptureResponse.find_by_capture_id(capture.id)
  end
  def amount
    phoenix_amount
  end
end
class BillingMembershipAuthorization < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_authorizations" 
  self.record_timestamps = false
end
class BillingMembershipCapture < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_captures" 
  self.record_timestamps = false
end
class BillingMembershipCaptureResponse < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "membership_capt_responses" 
  self.record_timestamps = false
end
class BillingChargeback < ActiveRecord::Base
  establish_connection "billing" 
  self.table_name = "chargebacks" 
  self.record_timestamps = false
  def phoenix_gateway
    gateway == 'mes' ? gateway : 'litle'
  end
end



class CustomerServicesOperations < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "operations"
  self.record_timestamps = false
end
class CustomerServicesNotes < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "notes"
  self.record_timestamps = false
end
class CustomerServicesNoteType < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "note_types" 
  self.record_timestamps = false
end
class CustomerServicesCommunication < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "communications" 
  self.record_timestamps = false
end
class CustomerServicesUser < ActiveRecord::Base
  establish_connection "customer_services" 
  self.table_name = "users" 
  self.inheritance_column = false
  self.record_timestamps = false
end



########################################################################################################
###########################   FUNCTIONS             ####################################################
########################################################################################################

def get_agent(author = 999)
  if author == 999
    DEFAULT_CREATED_BY
  else
    @users ||= CustomerServicesUser.all
    u = @users.select {|x| x.id == author }
    if u.empty?
      DEFAULT_CREATED_BY
    else
      a = PhoenixAgent.find_by_username(u[0].login)
      if a.nil?
        a = PhoenixAgent.new :username => u[0].login, :first_name => u[0].firstname, :last_name => u[0].lastname, 
            :email => u[0].mail
        a.save!
      end
      a.id
    end
  end
end

def add_operation(operation_date, object_class, object_id, description, operation_type, created_at = Time.now.utc, updated_at = Time.now.utc, author = 999)
  o = PhoenixOperation.new :operation_date => operation_date, :description => description, 
      :operation_type => (operation_type || Settings.operation_types.others)
  o.created_by_id = get_agent
  o.created_at = created_at
  o.cohort = @member.cohort
  unless object_class.nil?
    o.resource_type = object_class
    o.resource_id = object_id
  end
  o.updated_at = updated_at
  o.member_id = @member.uuid
  o.save!
end

def load_cancellation(cancel_date)
  add_operation(cancel_date, 'Member', @member.id, "Member canceled", Settings.operation_types.cancel, cancel_date, cancel_date) 
end

def set_last_billing_date_on_credit_card(member, transaction_date)
  cc = PhoenixCreditCard.find_by_active_and_member_id true, member.id
  if cc and (cc.last_successful_bill_date.nil? or cc.last_successful_bill_date < transaction_date)
    cc.update_attribute :last_successful_bill_date, transaction_date
  end
end

# If we store data in UTC, dates are converted to time using 00:00 am. So in CLT it will be the day before
def convert_from_date_to_time(x)
  if x.class == Date
    x.to_time + 12.hours
  elsif x.class == DateTime || x.class == Time
    x
  end
end

require 'import_communications'
