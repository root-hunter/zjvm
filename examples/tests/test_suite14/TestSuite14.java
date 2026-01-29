package test_suite14;
enum TestEnum {
   VALUE1,
   VALUE2,
   VALUE3;
}

public class TestSuite14 {
   public static void main(String[] var0) {
      TestEnum testEnum = TestEnum.VALUE2;
      switch (testEnum) {
         case VALUE2:
            System.out.println("Enum Value: VALUE2");
            break;
         default:
            System.out.println("Enum Value: Other");
            break;
      }
   }
}