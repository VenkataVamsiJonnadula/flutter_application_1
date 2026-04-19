import re
import random

mock_file = "lib/data/mock_data.dart"
model_file = "lib/billing/billing_item_model.dart"

addresses = [
    "123 MG Road, Mumbai", "45 Park Street, Kolkata", 
    "Residency Road, Bangalore", "Connaught Place, New Delhi",
    "Banjara Hills, Hyderabad", "Anna Nagar, Chennai", 
    "Civil Lines, Jaipur", "Koregaon Park, Pune"
]

def generate_phone():
    return "9" + "".join([str(random.randint(0, 9)) for _ in range(9)])

with open(mock_file, "r", encoding="utf-8") as f:
    mock_code = f.read()

# Extract unique names
matches = re.findall(r"customerName:\s*'([^']+)'", mock_code)
unique_names = list(set(matches))
print(f"Found {len(unique_names)} unique customers")

customers_dart = "import 'package:flutter/material.dart';\nimport '../customers/customer_model.dart';\n\n"
customers_dart += "class CustomerProvider with ChangeNotifier {\n"
customers_dart += "  final List<Customer> _customers = [\n"

customer_map = {}
for i, name in enumerate(unique_names):
    cid = f"C{i+1000}"
    customer_map[name] = cid
    phone = generate_phone()
    address = random.choice(addresses)
    customers_dart += f"    Customer(id: '{cid}', name: '{name}', phone: '{phone}', address: '{address}'),\n"

customers_dart += "  ];\n\n"
customers_dart += "  List<Customer> get customers => _customers;\n\n"
customers_dart += "  void addCustomer(Customer customer) {\n"
customers_dart += "    _customers.add(customer);\n"
customers_dart += "    notifyListeners();\n"
customers_dart += "  }\n"
customers_dart += "  \n  Customer? getCustomerById(String id) {\n"
customers_dart += "    try {\n"
customers_dart += "      return _customers.firstWhere((c) => c.id == id);\n"
customers_dart += "    } catch (e) {\n"
customers_dart += "      return null;\n"
customers_dart += "    }\n  }\n}\n"

with open("lib/providers/customer_provider.dart", "w", encoding="utf-8") as f:
    f.write(customers_dart)

# Update mock code
new_mock_code = mock_code
for name, cid in customer_map.items():
    new_mock_code = re.sub(rf"customerName:\s*'{name}'", f"customerId: '{cid}'", new_mock_code)

with open(mock_file, "w", encoding="utf-8") as f:
    f.write(new_mock_code)

# Update BillItem
with open(model_file, "r", encoding="utf-8") as f:
    model_code = f.read()

new_model_code = model_code.replace("final String customerName;", "final String customerId;")
new_model_code = new_model_code.replace("required this.customerName,", "required this.customerId,")

with open(model_file, "w", encoding="utf-8") as f:
    f.write(new_model_code)

print("Done generating customers and updating mock data and models.")
