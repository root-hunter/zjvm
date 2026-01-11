public class TestSuite6 {

    public static int add_twice(int x) {
        x = x + 2;
        return x;
    }

    public static void main(String[] args) {
        var a = 12;
        var b = 10000;

        int res = 0;

        for (int i = 0; i < b; i++) {
            res += add_twice(a + i);
        }

        int res2 = res / 10000; // 5013
    }
}