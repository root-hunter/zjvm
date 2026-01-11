public class TestSuite7 {

    public static int multiply_and_add(int x, int y) {
        x = x * 2;
        y = y + 3;
        return x + y;
    }

    public static void main(String[] args) {
        var a = 5;
        var b = 20;

        int res = 0;

        for (int i = 0; i < b; i++) {
            res += multiply_and_add(a + i, i);
        }

        int res2 = res / 20; // 41
    }
}
