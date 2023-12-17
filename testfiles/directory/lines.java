public class lines {
    int x;
    int y;
    int z;
    int d;
    int h;
    public void f () {
        if (x>1) {
            y=1;
            z=2;
        } 
        else 
        {
            h=2;
            z=1;
            y=3;
        }
    }

    int foo(){
        int x = 5;
        int y = 10;
        int z = 3;
        int b = 10;
        int n = 100;
        if (b > 10) {
            n = n + 5;
        } else {
            n = n + 100;
        }
        return (x+y)/(n+z);
    }

}