public class TestSuite2 {

    public static int multiply(int a, int b) {
        return a * b;
    }

    public static void main(String[] args) {
        var x = 5;
        var y = 10;
        var result = multiply(x, y);

        var total = result + x + y + 15;
    }
}