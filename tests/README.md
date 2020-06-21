# Tests
## run the tests:
1. in the terminal, cd to the tests folder.
2. run make to compile the tests
3. enter `./test` to run

## Test cases
in the [tests.c](./tests.c) file there are two testing functions:
1. [test_mayDestroy](./tests.c#L88), which tests the `mayDestroy()` function of a drone.
    - for each test case, if the test passed `test passed` will be printed, otherwise `test failed` will be printed.
2. [test_change_drone_position](./tests.c#L109) which tests the `change_drone_position` functio. for each test case:
    - if the test failed, `test failed` will be printed and the excpected output and real output will be displayed
    - if the test passed, `change drone location test passed` will be printed and the excepcted and real drone state will be printed.

## Adding additional test cases
1. in the [test_mayDestroy](./tests.c#L88) function, an array of test_data named [data](./tests.c#L90) is defined and containes the following data for a test case:
    - drone x coordinate
    - drone y coordinate
    - target x coordinate
    - target y coordinate
    - d, the maximum distance for hit
to add another test case just add another element with the required fields to the data array.
2. in the [test_change_drone_position](./tests.c#L109) function, an array of drone data named [data](./tests.c#L111) is defined and containes the following data for a test case:
    - drone x coordinate
    - drone y coordinate
    - drone angle
    - drone speed
to add another test case just add another element with the required fields to the data array.