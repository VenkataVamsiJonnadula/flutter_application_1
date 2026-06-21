import '../billing/billing_item_model.dart';
import '../billing/bill_model.dart';
import '../customers/customer_model.dart';

List<Customer> sharedMockCustomers = [
  Customer(id: 'C1000', name: 'Rajesh Khanna', phone: '9282716759', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1001', name: 'Sunita Sharma', phone: '9615817850', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1002', name: 'Anil Kapoor', phone: '9671651378', address: '123 MG Road, Mumbai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1003', name: 'Madhuri Dixit', phone: '9921724940', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1004', name: 'Sridevi Kapoor', phone: '9612384908', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1005', name: 'Amit Sharma', phone: '9411929688', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1006', name: 'Priya Patel', phone: '9866106367', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1007', name: 'Rajesh Kumar', phone: '9356790841', address: '123 MG Road, Mumbai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1008', name: 'Anjali Singh', phone: '9041877998', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1009', name: 'Suresh Raina', phone: '9231987628', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1010', name: 'Meera Reddy', phone: '9871502494', address: 'Civil Lines, Jaipur', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1011', name: 'Vikram Seth', phone: '9662951290', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1012', name: 'Sneha Gupta', phone: '9501362776', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1013', name: 'Arun Verma', phone: '9922742460', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1014', name: 'Kavita Iyer', phone: '9764554414', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1015', name: 'Rohan Das', phone: '9356844013', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1016', name: 'Deepa Nair', phone: '9805481680', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1017', name: 'Manoj Tiwari', phone: '9510466524', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1018', name: 'Pooja Hegde', phone: '9826243617', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1019', name: 'Sanjay Dutt', phone: '9684935149', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1020', name: 'Anita Desai', phone: '9692891941', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1021', name: 'Rahul Bose', phone: '9509718034', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1022', name: 'Shweta Tiwari', phone: '9006088576', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1023', name: 'Vijay Mallya', phone: '9179032360', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1024', name: 'Lata Mangesh', phone: '9306590980', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1025', name: 'Akshay Kumar', phone: '9079095929', address: 'Civil Lines, Jaipur', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1026', name: 'Kriti Sanon', phone: '9494347590', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1027', name: 'Varun Dhawan', phone: '9343451768', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1028', name: 'Alia Bhatt', phone: '9876532702', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1029', name: 'Ranbir Kapoor', phone: '9924215005', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1030', name: 'Ishaan Khattar', phone: '9510856301', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1031', name: 'Sara Ali Khan', phone: '9844534024', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1032', name: 'Kartik Aaryan', phone: '9261938649', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1033', name: 'Janhvi Kapoor', phone: '9233068483', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1034', name: 'Vicky Kaushal', phone: '9479502556', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1035', name: 'Katrina Kaif', phone: '9210708589', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1036', name: 'Ayushmann K.', phone: '9834672137', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1037', name: 'Tara Sutaria', phone: '9956390811', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1038', name: 'Aditya Roy', phone: '9139739525', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1039', name: 'Shraddha Kapoor', phone: '9552768124', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1040', name: 'Tiger Shroff', phone: '9452283352', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1041', name: 'Disha Patani', phone: '9433931066', address: '123 MG Road, Mumbai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1042', name: 'Sid Malhotra', phone: '9484967572', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1043', name: 'Kiara Advani', phone: '9585330058', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1044', name: 'Arjun Kapoor', phone: '9922958987', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1045', name: 'Malaika Arora', phone: '9582051591', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1046', name: 'Sonam Kapoor', phone: '9943857094', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1047', name: 'Anand Ahuja', phone: '9510505922', address: 'Civil Lines, Jaipur', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1048', name: 'Shahid Kapoor', phone: '9484471548', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1049', name: 'Mira Rajput', phone: '9479672629', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1050', name: 'Riteish D.', phone: '9183726648', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1051', name: 'Genelia D.', phone: '9376787641', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1052', name: 'Rajkummar Rao', phone: '9870734368', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1053', name: 'Patralekhaa', phone: '9635259942', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1054', name: 'John Abraham', phone: '9738046380', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1055', name: 'Bipasha Basu', phone: '9798157623', address: 'Koregaon Park, Pune', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1056', name: 'Karan Singh', phone: '9097853581', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1057', name: 'Abhishek B.', phone: '9759499629', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1058', name: 'Aishwarya Rai', phone: '9764369486', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1059', name: 'Saif Ali Khan', phone: '9539361730', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1060', name: 'Kareena Kapoor', phone: '9932572760', address: '123 MG Road, Mumbai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1061', name: 'Taimur Khan', phone: '9238086901', address: 'Anna Nagar, Chennai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1062', name: 'Ibrahim Khan', phone: '9520871183', address: 'Civil Lines, Jaipur', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1063', name: 'Soha Ali Khan', phone: '9420685714', address: '45 Park Street, Kolkata', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1064', name: 'Kunal Kemmu', phone: '9512182587', address: '123 MG Road, Mumbai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1065', name: 'Sara Khan', phone: '9729394330', address: 'Connaught Place, New Delhi', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1066', name: 'Amrita Singh', phone: '9429682253', address: '123 MG Road, Mumbai', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1067', name: 'Pankaj T.', phone: '9570295971', address: 'Banjara Hills, Hyderabad', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1068', name: 'Manoj Bajpayee', phone: '9418325549', address: 'Civil Lines, Jaipur', email: '', customerSince: DateTime(2023, 1, 1)),
  Customer(id: 'C1069', name: 'Nawazuddin S.', phone: '9104485703', address: 'Residency Road, Bangalore', email: '', customerSince: DateTime(2023, 1, 1)),
];

List<Bill> sharedMockItems = [];

void initializeSharedMockData() {
  if (sharedMockItems.isNotEmpty) return;
  final now = DateTime.now();
  final List<BillItem> tempItems = [
      BillItem(slNo: 1, date: DateTime(2026, 5, 20), customerId: 'C1000', description: 'Gold Coin', hsnSac: '71189', pcs: 1, grossWt: 15.000, stoneWt: 0.000, metalRate: 5800.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 2, date: DateTime(2026, 5, 12), customerId: 'C1001', description: 'Silver Coin', hsnSac: '71189', pcs: 3, grossWt: 50.000, stoneWt: 0.000, metalRate: 100.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 3, date: DateTime(2026, 5, 5), customerId: 'C1002', description: 'Silver Chain', hsnSac: '71189', pcs: 1, grossWt: 20.000, stoneWt: 0.000, metalRate: 100.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 4, date: DateTime(2026, 4, 25), customerId: 'C1003', description: 'Gold Ring', hsnSac: '71189', pcs: 1, grossWt: 3.446, stoneWt: 0.080, metalRate: 6500.0, va: 2200.0, stoneValue: 400.0, discAmt: 0.0
      ),
      BillItem(slNo: 5, date: DateTime(2026, 4, 10), customerId: 'C1004', description: 'Gold Necklace', hsnSac: '71189', pcs: 1, grossWt: 20.558, stoneWt: 0.200, metalRate: 6500.0, va: 13200.0, stoneValue: 600.0, discAmt: 127.0
      ),
      BillItem(slNo: 6, date: DateTime(2026, 3, 28), customerId: 'C1005', description: 'Gold Earrings', hsnSac: '71189', pcs: 1, grossWt: 8.500, stoneWt: 0.100, metalRate: 6500.0, va: 4500.0, stoneValue: 200.0, discAmt: 0.0
      ),
      BillItem(slNo: 7, date: DateTime(2026, 3, 15), customerId: 'C1006', description: 'Silver Bracelet', hsnSac: '71189', pcs: 1, grossWt: 45.000, stoneWt: 0.000, metalRate: 100.0, va: 800.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 8, date: DateTime(2026, 2, 22), customerId: 'C1007', description: 'Gold Bangle', hsnSac: '71189', pcs: 2, grossWt: 24.200, stoneWt: 0.350, metalRate: 6500.0, va: 12000.0, stoneValue: 500.0, discAmt: 525.0
      ),
      BillItem(slNo: 9, date: DateTime(2026, 2, 10), customerId: 'C1008', description: 'Silver Anklet', hsnSac: '71189', pcs: 1, grossWt: 60.000, stoneWt: 0.000, metalRate: 100.0, va: 1200.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 10, date: DateTime(2026, 1, 25), customerId: 'C1009', description: 'Gold Pendant', hsnSac: '71189', pcs: 1, grossWt: 5.350, stoneWt: 0.050, metalRate: 6500.0, va: 3200.0, stoneValue: 150.0, discAmt: 0.0
      ),
      BillItem(slNo: 11, date: DateTime(2026, 1, 12), customerId: 'C1010', description: 'Gold Chain', hsnSac: '71189', pcs: 1, grossWt: 12.000, stoneWt: 0.000, metalRate: 6500.0, va: 6000.0, stoneValue: 300.0, discAmt: 0.0
      ),
      BillItem(slNo: 12, date: DateTime(2025, 12, 28), customerId: 'C1011', description: 'Silver Ring', hsnSac: '71189', pcs: 1, grossWt: 6.500, stoneWt: 0.200, metalRate: 100.0, va: 250.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 13, date: DateTime(2025, 12, 15), customerId: 'C1012', description: 'Gold Necklace', hsnSac: '71189', pcs: 1, grossWt: 42.150, stoneWt: 0.850, metalRate: 6500.0, va: 25000.0, stoneValue: 1000.0, discAmt: 450.0
      ),
      BillItem(slNo: 14, date: DateTime(2025, 11, 20), customerId: 'C1013', description: 'Silver Spoon', hsnSac: '71189', pcs: 1, grossWt: 35.000, stoneWt: 0.000, metalRate: 100.0, va: 500.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 15, date: DateTime(2025, 11, 5), customerId: 'C1014', description: 'Gold Coin', hsnSac: '71189', pcs: 1, grossWt: 5.000, stoneWt: 0.000, metalRate: 5800.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 16, date: DateTime.parse('2023-11-08'), customerId: 'C1015', description: 'Gold Bracelet', hsnSac: '71189', pcs: 1, grossWt: 18.750, stoneWt: 0.150, metalRate: 6500.0, va: 9500.0, stoneValue: 400.0, discAmt: 0.0
      ),
      BillItem(slNo: 17, date: DateTime.parse('2023-12-15'), customerId: 'C1016', description: 'Silver Chain', hsnSac: '71189', pcs: 1, grossWt: 30.000, stoneWt: 0.000, metalRate: 100.0, va: 600.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 18, date: DateTime.parse('2024-01-12'), customerId: 'C1017', description: 'Gold Ring', hsnSac: '71189', pcs: 1, grossWt: 4.200, stoneWt: 0.120, metalRate: 6500.0, va: 2800.0, stoneValue: 100.0, discAmt: 20.0
      ),
      BillItem(slNo: 19, date: DateTime.parse('2024-02-04'), customerId: 'C1018', description: 'Gold Ear Studs', hsnSac: '71189', pcs: 1, grossWt: 2.800, stoneWt: 0.000, metalRate: 6500.0, va: 2200.0, stoneValue: 100.0, discAmt: 0.0
      ),
      BillItem(slNo: 20, date: DateTime.parse('2024-03-10'), customerId: 'C1019', description: 'Silver Idol', hsnSac: '71189', pcs: 1, grossWt: 150.000, stoneWt: 0.000, metalRate: 100.0, va: 3000.0, stoneValue: 500.0, discAmt: 0.0
      ),
      BillItem(slNo: 21, date: DateTime.parse('2024-04-22'), customerId: 'C1020', description: 'Gold Mangalsutra', hsnSac: '71189', pcs: 1, grossWt: 15.600, stoneWt: 0.400, metalRate: 6500.0, va: 11000.0, stoneValue: 600.0, discAmt: 400.0
      ),
      BillItem(slNo: 22, date: DateTime.parse('2024-05-09'), customerId: 'C1021', description: 'Silver Coin', hsnSac: '71189', pcs: 10, grossWt: 100.000, stoneWt: 0.000, metalRate: 100.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 23, date: DateTime.parse('2024-06-30'), customerId: 'C1022', description: 'Gold Nose Pin', hsnSac: '71189', pcs: 1, grossWt: 0.550, stoneWt: 0.050, metalRate: 6500.0, va: 850.0, stoneValue: 50.0, discAmt: 50.0
      ),
      BillItem(slNo: 24, date: DateTime.parse('2024-07-15'), customerId: 'C1023', description: 'Gold Bangle', hsnSac: '71189', pcs: 2, grossWt: 30.000, stoneWt: 0.000, metalRate: 6500.0, va: 14000.0, stoneValue: 1000.0, discAmt: 0.0
      ),
      BillItem(slNo: 25, date: DateTime.parse('2024-08-11'), customerId: 'C1024', description: 'Silver Plate', hsnSac: '71189', pcs: 1, grossWt: 250.000, stoneWt: 0.000, metalRate: 100.0, va: 4500.0, stoneValue: 0.0, discAmt: 500.0
      ),
      BillItem(slNo: 26, date: DateTime.parse('2024-09-28'), customerId: 'C1025', description: 'Gold Choker', hsnSac: '71189', pcs: 1, grossWt: 55.000, stoneWt: 1.500, metalRate: 6500.0, va: 35000.0, stoneValue: 2000.0, discAmt: 750.0
      ),
      BillItem(slNo: 27, date: DateTime.parse('2024-10-14'), customerId: 'C1026', description: 'Silver Toe Ring', hsnSac: '71189', pcs: 2, grossWt: 10.000, stoneWt: 0.000, metalRate: 100.0, va: 300.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 28, date: DateTime.parse('2024-11-02'), customerId: 'C1027', description: 'Gold Tikka', hsnSac: '71189', pcs: 1, grossWt: 6.800, stoneWt: 0.200, metalRate: 6500.0, va: 4800.0, stoneValue: 200.0, discAmt: 0.0
      ),
      BillItem(slNo: 29, date: DateTime.parse('2024-12-19'), customerId: 'C1028', description: 'Gold Kada', hsnSac: '71189', pcs: 1, grossWt: 35.400, stoneWt: 0.000, metalRate: 6500.0, va: 18000.0, stoneValue: 1000.0, discAmt: 100.0
      ),
      BillItem(slNo: 30, date: DateTime.parse('2025-01-25'), customerId: 'C1029', description: 'Silver Glass', hsnSac: '71189', pcs: 2, grossWt: 180.000, stoneWt: 0.000, metalRate: 100.0, va: 2400.0, stoneValue: 100.0, discAmt: 0.0
      ),
      BillItem(slNo: 31, date: DateTime.parse('2025-02-14'), customerId: 'C1030', description: 'Gold Waist Belt', hsnSac: '71189', pcs: 1, grossWt: 120.000, stoneWt: 5.000, metalRate: 6500.0, va: 65000.0, stoneValue: 5000.0, discAmt: 500.0
      ),
      BillItem(slNo: 32, date: DateTime.parse('2025-03-05'), customerId: 'C1031', description: 'Silver Bowl', hsnSac: '71189', pcs: 1, grossWt: 85.000, stoneWt: 0.000, metalRate: 100.0, va: 1200.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 33, date: DateTime.parse('2025-04-29'), customerId: 'C1032', description: 'Gold Chain', hsnSac: '71189', pcs: 1, grossWt: 22.500, stoneWt: 0.000, metalRate: 6500.0, va: 9000.0, stoneValue: 500.0, discAmt: 750.0
      ),
      BillItem(slNo: 34, date: DateTime.parse('2025-05-12'), customerId: 'C1033', description: 'Silver Earrings', hsnSac: '71189', pcs: 1, grossWt: 12.000, stoneWt: 0.500, metalRate: 100.0, va: 450.0, stoneValue: 50.0, discAmt: 50.0
      ),
      BillItem(slNo: 35, date: DateTime.parse('2025-06-30'), customerId: 'C1034', description: 'Gold Ring', hsnSac: '71189', pcs: 1, grossWt: 5.900, stoneWt: 0.300, metalRate: 6500.0, va: 3500.0, stoneValue: 100.0, discAmt: 0.0
      ),
      BillItem(slNo: 36, date: DateTime.parse('2025-07-22'), customerId: 'C1035', description: 'Gold Coin', hsnSac: '71189', pcs: 2, grossWt: 20.000, stoneWt: 0.000, metalRate: 5800.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 37, date: DateTime.parse('2025-08-11'), customerId: 'C1036', description: 'Silver Chain', hsnSac: '71189', pcs: 1, grossWt: 40.000, stoneWt: 0.000, metalRate: 100.0, va: 800.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 38, date: DateTime.parse('2025-09-08'), customerId: 'C1037', description: 'Gold Necklace', hsnSac: '71189', pcs: 1, grossWt: 32.450, stoneWt: 0.250, metalRate: 6500.0, va: 18000.0, stoneValue: 800.0, discAmt: 100.0
      ),
      BillItem(slNo: 39, date: DateTime.parse('2023-01-18'), customerId: 'C1038', description: 'Silver Bracelet', hsnSac: '71189', pcs: 1, grossWt: 28.000, stoneWt: 0.000, metalRate: 100.0, va: 600.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 40, date: DateTime.parse('2023-02-28'), customerId: 'C1039', description: 'Gold Jhumka', hsnSac: '71189', pcs: 1, grossWt: 14.200, stoneWt: 0.600, metalRate: 6500.0, va: 9500.0, stoneValue: 500.0, discAmt: 400.0
      ),
      BillItem(slNo: 41, date: DateTime.parse('2023-03-12'), customerId: 'C1040', description: 'Gold Pendant', hsnSac: '71189', pcs: 1, grossWt: 3.200, stoneWt: 0.000, metalRate: 6500.0, va: 2200.0, stoneValue: 100.0, discAmt: 100.0
      ),
      BillItem(slNo: 42, date: DateTime.parse('2023-04-25'), customerId: 'C1041', description: 'Silver Lamp', hsnSac: '71189', pcs: 2, grossWt: 300.000, stoneWt: 0.000, metalRate: 100.0, va: 6000.0, stoneValue: 1000.0, discAmt: 0.0
      ),
      BillItem(slNo: 43, date: DateTime.parse('2023-05-19'), customerId: 'C1042', description: 'Gold Bangle', hsnSac: '71189', pcs: 1, grossWt: 12.800, stoneWt: 0.100, metalRate: 6500.0, va: 7000.0, stoneValue: 300.0, discAmt: 50.0
      ),
      BillItem(slNo: 44, date: DateTime.parse('2023-06-05'), customerId: 'C1043', description: 'Silver Ring', hsnSac: '71189', pcs: 1, grossWt: 8.000, stoneWt: 0.400, metalRate: 100.0, va: 300.0, stoneValue: 40.0, discAmt: 0.0
      ),
      BillItem(slNo: 45, date: DateTime.parse('2023-07-14'), customerId: 'C1044', description: 'Gold Chain', hsnSac: '71189', pcs: 1, grossWt: 9.500, stoneWt: 0.000, metalRate: 6500.0, va: 4500.0, stoneValue: 250.0, discAmt: 0.0
      ),
      BillItem(slNo: 46, date: DateTime.parse('2023-08-23'), customerId: 'C1045', description: 'Gold Coin', hsnSac: '71189', pcs: 5, grossWt: 40.000, stoneWt: 0.000, metalRate: 5800.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 47, date: DateTime.parse('2023-09-30'), customerId: 'C1046', description: 'Silver Anklet', hsnSac: '71189', pcs: 1, grossWt: 55.000, stoneWt: 0.000, metalRate: 100.0, va: 1100.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 48, date: DateTime.parse('2023-10-11'), customerId: 'C1047', description: 'Gold Ring', hsnSac: '71189', pcs: 1, grossWt: 6.750, stoneWt: 0.500, metalRate: 6500.0, va: 4000.0, stoneValue: 200.0, discAmt: 25.0
      ),
      BillItem(slNo: 49, date: DateTime.parse('2023-11-19'), customerId: 'C1048', description: 'Gold Necklace', hsnSac: '71189', pcs: 1, grossWt: 25.300, stoneWt: 0.300, metalRate: 6500.0, va: 15000.0, stoneValue: 700.0, discAmt: 200.0
      ),
      BillItem(slNo: 50, date: DateTime.parse('2023-12-05'), customerId: 'C1049', description: 'Silver Spoon', hsnSac: '71189', pcs: 4, grossWt: 120.000, stoneWt: 0.000, metalRate: 100.0, va: 2000.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 51, date: DateTime.parse('2024-01-29'), customerId: 'C1050', description: 'Gold Bracelet', hsnSac: '71189', pcs: 1, grossWt: 14.500, stoneWt: 0.000, metalRate: 6500.0, va: 7500.0, stoneValue: 400.0, discAmt: 150.0
      ),
      BillItem(slNo: 52, date: DateTime.parse('2024-02-18'), customerId: 'C1051', description: 'Silver Chain', hsnSac: '71189', pcs: 1, grossWt: 18.000, stoneWt: 0.000, metalRate: 100.0, va: 400.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 53, date: DateTime.parse('2024-03-25'), customerId: 'C1052', description: 'Gold Ear Studs', hsnSac: '71189', pcs: 1, grossWt: 3.500, stoneWt: 0.100, metalRate: 6500.0, va: 2500.0, stoneValue: 100.0, discAmt: 0.0
      ),
      BillItem(slNo: 54, date: DateTime.parse('2024-04-12'), customerId: 'C1053', description: 'Silver Idol', hsnSac: '71189', pcs: 1, grossWt: 500.000, stoneWt: 0.000, metalRate: 100.0, va: 12000.0, stoneValue: 2000.0, discAmt: 1000.0
      ),
      BillItem(slNo: 55, date: DateTime.parse('2024-05-30'), customerId: 'C1054', description: 'Gold Mangalsutra', hsnSac: '71189', pcs: 1, grossWt: 20.800, stoneWt: 0.600, metalRate: 6500.0, va: 14000.0, stoneValue: 800.0, discAmt: 100.0
      ),
      BillItem(slNo: 56, date: DateTime.parse('2024-06-11'), customerId: 'C1055', description: 'Silver Coin', hsnSac: '71189', pcs: 20, grossWt: 200.000, stoneWt: 0.000, metalRate: 100.0, va: 0.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 57, date: DateTime.parse('2024-07-23'), customerId: 'C1056', description: 'Gold Nose Pin', hsnSac: '71189', pcs: 1, grossWt: 0.700, stoneWt: 0.100, metalRate: 6500.0, va: 900.0, stoneValue: 50.0, discAmt: 50.0
      ),
      BillItem(slNo: 58, date: DateTime.parse('2024-08-05'), customerId: 'C1057', description: 'Gold Bangle', hsnSac: '71189', pcs: 2, grossWt: 45.000, stoneWt: 0.500, metalRate: 6500.0, va: 22000.0, stoneValue: 1500.0, discAmt: 750.0
      ),
      BillItem(slNo: 59, date: DateTime.parse('2024-09-17'), customerId: 'C1058', description: 'Silver Plate', hsnSac: '71189', pcs: 1, grossWt: 400.000, stoneWt: 0.000, metalRate: 100.0, va: 7500.0, stoneValue: 500.0, discAmt: 0.0
      ),
      BillItem(slNo: 60, date: DateTime.parse('2024-10-09'), customerId: 'C1059', description: 'Gold Choker', hsnSac: '71189', pcs: 1, grossWt: 65.000, stoneWt: 2.000, metalRate: 6500.0, va: 45000.0, stoneValue: 3000.0, discAmt: 500.0
      ),
      BillItem(slNo: 61, date: DateTime.parse('2024-11-25'), customerId: 'C1060', description: 'Silver Toe Ring', hsnSac: '71189', pcs: 2, grossWt: 12.000, stoneWt: 0.000, metalRate: 100.0, va: 400.0, stoneValue: 0.0, discAmt: 0.0
      ),
      BillItem(slNo: 62, date: DateTime.parse('2024-12-11'), customerId: 'C1061', description: 'Gold Tikka', hsnSac: '71189', pcs: 1, grossWt: 8.200, stoneWt: 0.300, metalRate: 6500.0, va: 5500.0, stoneValue: 250.0, discAmt: 100.0
      ),
      BillItem(slNo: 63, date: DateTime.parse('2025-01-02'), customerId: 'C1062', description: 'Gold Kada', hsnSac: '71189', pcs: 1, grossWt: 42.000, stoneWt: 0.000, metalRate: 6500.0, va: 22000.0, stoneValue: 1200.0, discAmt: 200.0
      ),
      BillItem(slNo: 64, date: DateTime.parse('2025-02-18'), customerId: 'C1063', description: 'Silver Glass', hsnSac: '71189', pcs: 6, grossWt: 540.000, stoneWt: 0.000, metalRate: 100.0, va: 7000.0, stoneValue: 500.0, discAmt: 500.0
      ),
      BillItem(slNo: 65, date: DateTime.parse('2025-03-10'), customerId: 'C1064', description: 'Gold Waist Belt', hsnSac: '71189', pcs: 1, grossWt: 150.000, stoneWt: 8.000, metalRate: 6500.0, va: 85000.0, stoneValue: 7000.0, discAmt: 0.0
      ),
      BillItem(slNo: 66, date: DateTime.parse('2025-04-22'), customerId: 'C1065', description: 'Silver Bowl', hsnSac: '71189', pcs: 2, grossWt: 150.000, stoneWt: 0.000, metalRate: 100.0, va: 2500.0, stoneValue: 100.0, discAmt: 100.0
      ),
      BillItem(slNo: 67, date: DateTime.parse('2025-05-09'), customerId: 'C1066', description: 'Gold Chain', hsnSac: '71189', pcs: 1, grossWt: 28.400, stoneWt: 0.000, metalRate: 6500.0, va: 12000.0, stoneValue: 600.0, discAmt: 200.0
      ),
      BillItem(slNo: 68, date: DateTime.parse('2025-06-30'), customerId: 'C1067', description: 'Silver Earrings', hsnSac: '71189', pcs: 1, grossWt: 15.500, stoneWt: 0.800, metalRate: 100.0, va: 550.0, stoneValue: 80.0, discAmt: 0.0
      ),
      BillItem(slNo: 69, date: DateTime.parse('2025-07-15'), customerId: 'C1068', description: 'Gold Ring', hsnSac: '71189', pcs: 1, grossWt: 7.250, stoneWt: 0.450, metalRate: 6500.0, va: 4500.0, stoneValue: 200.0, discAmt: 0.0
      ),
      BillItem(slNo: 70, date: DateTime.parse('2025-08-25'), customerId: 'C1069', description: 'Gold Necklace', hsnSac: '71189', pcs: 1, grossWt: 55.600, stoneWt: 1.200, metalRate: 6500.0, va: 32000.0, stoneValue: 1400.0, discAmt: 0.0
      ),
  ];

  sharedMockItems = tempItems.map((item) {
    final customer = sharedMockCustomers.firstWhere(
      (c) => c.id == item.customerId,
      orElse: () => Customer(
        id: item.customerId,
        name: 'Customer ${item.customerId}',
        phone: 'NA',
        address: 'NA',
        email: '',
        customerSince: now,
      ),
    );

    return Bill(
      slNo: item.slNo,
      invoiceNumber: 'SVJ/${item.date.year}/${item.slNo.toString().padLeft(4, '0')}',
      date: item.date,
      customerId: item.customerId,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerAddress: customer.address,
      items: [item],
    );
  }).toList();

  sharedMockItems.sort((a, b) => b.date.compareTo(a.date));
}