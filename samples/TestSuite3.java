public class TestSuite3 {

    public static int divide(int a, int b) {
        return a / b;
    }

    public static void main(String[] args) {
        var x = 10;
        var y = 5;
        var result = divide(x, y);

        var total = (result + x + y + 15);

        var rem = total % 8;
    }
}