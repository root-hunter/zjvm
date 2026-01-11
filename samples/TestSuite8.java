public class TestSuite8 {

    public static int fibonacci(int n) {
        if (n <= 1) {
            return n;
        }
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    public static void main(String[] args) {
        var a = 5;
        var b = 5;

        int c = a + b; // 10

        int res = fibonacci(c);

        int d = res - 40; // 55 - 40 = 15

        int res2 = fibonacci(d); // fibonacci(15) = 610

        int e = res2 - 590; // 610 - 590 = 20

        int res3 = fibonacci(e); // fibonacci(20) = 6765
    }
}