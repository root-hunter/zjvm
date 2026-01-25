public class TestSuite14 {
   public static void main(String[] var0) {
      System.out.println("This is Test Suite 14.");
      System.out.println("Testing longs and floats.");

      long longVar = 1234567890123456789L;
      System.out.println("Long Value: " + longVar); // Long Value: 1234567890123456789
      long longResult = longVar * 2;
      System.out.println("Long Result (longVar * 2): " + longResult); // Long Result (longVar * 2): 2469135780246913578

      float floatVar = 0.1f;
      System.out.println("Float Value: " + floatVar); // Float Value: 0.1
      float floatResult = floatVar + 0.2f;
      System.out.println("Float Result (floatVar + 0.2): " + floatResult); // Float Result (floatVar + 0.2): 0.3

      double doubleVar = 0.1;

      System.out.println("Double Value: " + doubleVar); // Double Value: 0.1
      double doubleResult = doubleVar + 0.2;
      System.out.println("Double Result (doubleVar + 0.2): " + doubleResult); // Double Result (doubleVar + 0.2): 0.3

      for (int i = 0; i < 500000; i++) {
         long loopLong = longVar + i;
         System.out.println("Loop " + i + ": " + loopLong);
      }
   }
}