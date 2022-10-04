# Coder Templates

This is a collection of some of my personal templates for my [Coder OSS](https://coder.com) instance.

## Templates

The following templates are included.

- **`general`**  
  Includes the following toolchanins and apps:
    - NodeJS, NPM
    - Go
    - Elixir, IEX
    - .NET 6
    - Rust, Cargo
    - Taskfile
    - MySQL Client
    - Hugo
    - Corepack, Yarn

- **`general-mysql`**  
  Includes all toolchains and apps as the `general` template. Also includes the following services:
    - MariaDB Server
    - PHPMyAdmin

## Usage

First of all, clone this repository.
```
git clone --depth 1 https://github.com/zekrotja/coder-templates .
```

After that, you can use the `wrapper` script to `create` and `push` templates to your coder instance.

> You might need to add the executable permission to the script first.
> ```
> chmod +d ./wrapper
> ```

Example:
```
./wrapper create general-mysql
```

You can also give the template a custom name:
```
./wrapper create my-template general-mysql
```

## Contribution

Feel free to extend the current templates as you need or add new templates which might be usedful and contribute them to the project. :)