use array::ArrayTrait;

#[derive(Drop)]
struct MyStruct {
    size: usize,
    data: Array<u128>
}

trait MyStructTrait {
    fn new(size: usize, data: Array<u128>) -> MyStruct;
    fn pass_by_value(size: usize) -> usize;
    fn append(ref self: MyStruct, value: u128);
}

impl MyStructTraitImpl of MyStructTrait {
    fn new(size: usize, data: Array<u128>) -> MyStruct {
        MyStruct {size, data}
    }

    fn pass_by_value(size: usize) -> usize {
        size + 1
    }

    fn append(ref self: MyStruct, value: u128) {
        let MyStruct{size: mut old_size, mut data} = self;
        let new_size = MyStructTrait::pass_by_value(old_size);
        data.append(value);
        self = MyStruct{size: new_size, data: data};
    }
}