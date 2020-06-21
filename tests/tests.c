#include <stdint.h>
#include <stdio.h>
#include <math.h>

extern uint16_t random_generator_1();
extern double x;
extern double y;
extern double angle;
extern double speed;
extern double target_x;
extern double target_y ;
extern double d;
extern int mayDestroy();
extern void change_drone_position();

#define epsilon 0.00001

typedef struct
{
    double x;
    double y;
    double angle;
    double speed;
} drone;

typedef struct {
    double x;
    double y;
    double target_x;
    double target_y;
    double d;
} test_data;

unsigned lfsr1(void)
{
    uint16_t start_state = 0xACE1u;  /* Any nonzero start state will work. */
    uint16_t lfsr = start_state, my_lfsr;
    uint16_t bit;                    /* Must be 16-bit to allow bit<<15 later in the code */
    unsigned period = 0;

    do
    {   /* taps: 16 14 13 11; feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1 */
        my_lfsr = random_generator_1();
        bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) /* & 1u */;
        lfsr = (lfsr >> 1) | (bit << 15);
        printf("true lfsr: %X, my lfsr: %X\n", lfsr, my_lfsr);
        if (my_lfsr != lfsr){
            printf("test failed\n");
            return lfsr;
        }
        ++period;
    }
    while (period != 10);

    return period;
}

double euclidian_distance(double x1, double y1, double x2, double y2){
    return sqrt((x1 - x2)*(x1 - x2) + (y1 - y2)*(y1 - y2));
}

double generate_random_coordinates(){
    return 0.0;
}

int loc = 0;
unsigned short random_generator2(){
    static short int array[] = {32,34565,435,3462,2462,462,35135,2446,135,3903};
    static int size = sizeof(array)/sizeof(unsigned short);
    unsigned short ret = array[loc];
    loc = (loc + 1)%size;
    return ret;
}


double scale(unsigned short toscale, double a, double b){
    double scaled = (((double)toscale)/65535)*(b-a) + a;
    return scaled;
}

double absolute(double val){
    return val < 0 ? -val : val;
}
double deg_to_rad(double angle){
    return (angle*M_PI)/180;
}

void test_mayDestroy(){
    // add more test cases here
    test_data data[] = {{23.02, 33.5, 3.465, 43.54, 30.0}, {34.02, 73.5, 20.29, 15.09, 30.0}};
    for (int i = 0; i < sizeof(data)/sizeof(test_data); i++){
        test_data coordinates = data[i];
        x = coordinates.x;
        y = coordinates.y;
        target_x = coordinates.target_x;
        target_y = coordinates.target_y;
        double distance = euclidian_distance(x,y,target_x,target_y);
        d = coordinates.d;
        printf("distance: %f\n", distance);
        int maydest = mayDestroy();
        if ((distance <= d && maydest) || (distance > d && !maydest)){
            printf("test passed\n");
        } else {
            printf("test failed\n");
        }
    }
}

void test_change_drone_position(){
    // add more test cases here
    drone data[] = {{23.02, 33.5, 35.0, 20.0}, {34.02, 73.5, 270.0, 10.23},{95.0, 32.0, 3.0, 3}};
    for (int i = 0; i < sizeof(data)/sizeof(drone); i++){
        int begin_loc = loc;
        drone drone = data[i];
        x = drone.x;
        y = drone.y;
        angle = drone.angle;
        speed = drone.speed;
        double new_x = drone.x + cos(deg_to_rad(angle))*speed;
        if (new_x >= 100.0){
            new_x = new_x - 100.0;
        }
        double new_y = drone.y + sin(deg_to_rad(angle))*speed;
        if (new_y >= 100.0){
            new_y = new_y - 100.0;
        }
        double delta_angle = scale(random_generator2(), -60.0,60.0);
        //printf("delta angle: %f\n", delta_angle);
        double new_angle = (drone.angle + delta_angle);
        if (new_angle >= 360){
            new_angle = new_angle - 360;
        }
        if (new_angle < 0){
            new_angle = new_angle + 360;
        }
        double delta_speed = scale(random_generator2(), -10,10);
        //printf("delta speed: %f\n", delta_speed);
        double new_speed = drone.speed + delta_speed;
        if (new_speed >= 100.0){
            new_speed = 100.0;
        }
        if (new_speed < 0){
            new_speed = 0;
        }
        loc = begin_loc;
        change_drone_position();
        int bool = 1;
        if (absolute(x - new_x) > epsilon){
            printf("test failed. expected x: %.6f, but got %.6f\n", new_x, x);
            bool = 0;
        }
        if (absolute(y - new_y) > epsilon){
            printf("test failed. expected y: %.6f, but got %.6f\n", new_y, y);
            bool = 0;
        }
        if (absolute(angle - new_angle) > epsilon){
            printf("test failed. expected angle: %.6f, but got %.6f\n", new_angle, angle);
            bool = 0;
        }
        if (absolute(speed - new_speed) > epsilon){
            printf("test failed. expected speed: %.6f, but got %.6f\n", new_speed, speed);
            bool = 0;
        }
        if (bool){
            printf("change drone location test passed\n");
            printf("excpected drone:\n\tx: %f,\n\ty:%f, \n\tangle:%f, \n\tspeed:%f\n", new_x, new_y, new_angle, new_speed);
            printf("drone got:\n\tx: %f,\n\ty:%f, \n\tangle:%f, \n\tspeed:%f\n", x, y, angle, speed);
        }
    }
}

int main(int argc, char* argv[]) {
    // for (int j = 0; j < 20; j++){
    //     printf("%d\n", random_generator2());
    // }
    //lfsr1();
    test_mayDestroy();
    test_change_drone_position();
}