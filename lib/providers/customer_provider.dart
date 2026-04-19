import 'package:flutter/material.dart';
import '../customers/customer_model.dart';

class CustomerProvider with ChangeNotifier {
  final List<Customer> _customers = [];

  CustomerProvider() {
    _initializeCustomers();
  }

  void _initializeCustomers() {
    _customers.addAll([
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
    ]);
  }

  List<Customer> get customers => _customers;

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
  }
  
  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  void updateCustomer(Customer updatedCustomer) {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index != -1) {
      _customers[index] = updatedCustomer;
      notifyListeners();
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
