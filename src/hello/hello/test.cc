#include <cstdlib>
#include <iostream>
using namespace std;
//#include "v8.h"
void *p;
int main(){
    p = malloc(7);
    p = 0;
    cout << "This sucks.";
    return 0;
}
