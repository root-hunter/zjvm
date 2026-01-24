public class TestSuite12 {
   public static void main(String[] var0) {
      System.out.println("This is Test Suite 12.");

      var x = 42;
      var y = x * 2;
      System.out.println("X = " + x); // X = 42
      System.out.println("Y = " + y); // Y = 84
      var z = y / 3.0;
      System.out.println("Z = " + z); // Z = 28.0

      var a = 10;
      var b = 20;
      if (a < b) {
         System.out.println("A is less than B");
      } else {
         System.out.println("A is not less than B");
      }

      var p = 15;
      var q = 15;
      if (p >= q) {
         System.out.println("P is greater than or equal to Q");
      } else {
         System.out.println("P is less than Q");
      }

      final double pi = 3.14159;
      System.out.println("Value of Pi: " + pi);

      final int maxCount = 31;

      for (int i = 0; i < maxCount; i++) {
         if (i % 15 == 0) {
            System.out.println(i + " is divisible by 15");
         } else if (i % 5 == 0) {
            System.out.println(i + " is divisible by 5");
         } else if (i % 3 == 0) {
            System.out.println(i + " is divisible by 3");
         }
      }
   }
}