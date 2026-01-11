public class TestSuite5 {

    public static int exponentiate(int base, int exp) {
        int result = 1;
        for (int i = 0; i < exp; i++) {
            result = result * base;
        }
        return result;
    }

    public static void main(String[] args) {
        var a = 12;
        var b = 4;

        var res = exponentiate(a, b); // 20736
    }
}