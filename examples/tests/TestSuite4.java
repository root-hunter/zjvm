public class TestSuite4 {

    public static int divide(int a, int b) {
        return a / b;
    }

    public static int multiply(int a, int b) {
        return a * b;
    }

    public static void main(String[] args) {
        var a = 3200;
        var b = 8;

        var res = multiply(a, b); // 25600

        var c = 2000;
        var d = 4;

        var res2 = divide(c, d); // 500

        var total = res + res2; // 26100

        if (total > 25000) {
            total = total - 2000; // 24100
        } else {
            total = total + 2000; // not executed
        }
    }
}