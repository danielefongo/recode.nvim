use crate::common::add_one;

pub fn my_function(param1: i32, param2: i32) {
    let param3: i32 = 3;
    let param4: i32 = 3;
    let x = match param1 {
        1 => 1,
        _ => add_one(param3),
    };
    match 1 {
        1 => 1,
        _ => add_one(param4),
    };
    let add_one: fn(i32) -> i32 = |_| 42;
}
