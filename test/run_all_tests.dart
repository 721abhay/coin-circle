import 'automated_bug_detector.dart' as bug_tests;
import 'security_test.dart' as security_tests;
import 'database_test.dart' as db_tests;
import 'backend_test.dart' as backend_tests;
import 'ui_test.dart' as ui_tests;

void main() {
  print('🤖 Running Complete Test Suite...\n');
  
  print('1️⃣ Bug Detection Tests');
  bug_tests.main();
  
  print('\n2️⃣ Security Tests');
  security_tests.main();
  
  print('\n3️⃣ Database Tests');
  db_tests.main();
  
  print('\n4️⃣ Backend/API Tests');
  backend_tests.main();
  
  print('\n5️⃣ UI/UX Tests');
  ui_tests.main();
  
  print('\n✅ All Tests Complete!');
}
