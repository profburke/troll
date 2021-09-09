## Troll

[**Troll**](http://hjemmesider.diku.dk/~torbenm/Troll/) is a language for describing dice rolls for various board games, RPGs, or other circumstances where you need a little structured randomness in your life. Troll was created by [Professor Torben Mogensen](http://hjemmesider.diku.dk/~torbenm/), a faculty member at [DIKU](https://di.ku.dk/).

This Swift package is an interpreter for Troll. The package is also named Troll, which will certainly cause no confusion with the name of the language :)

Troll makes simple dice rolling, simple; and it makes complicated dice rolling, possible. Here's a Troll script to roll three 6-sided dice and add them up: `sum 3d6`. And here's one to keep re-rolling five 20-sided dice until they all show different numbers: 

```
repeat x := 5d20 until 5 = (count different x)
```

For more complicated examples, see the [Examples directory](https://github.com/profburke/troll/tree/main/Examples) and/or Troll's website.

## How to Use

Read the [interpreter documentation](https://github.com/profburke/troll/blob/main/Documentation/InterpreterUse.md) for details on executing a Troll script from a file, using the interactive REPL tool, and installing either a pre-compiled binary or building from source.

## How to Include in Your Swift Project

To use the Troll package in your program, include the following line in the dependency section of your `Package.swift` file:

```
.package(url: "https://github.com/profburke/Troll", from: "0.5.0")
```

You also must list `Troll` in the dependencies section of your target descriptor. 

_The version number shown above may be out-of-date, check the GitHub repository for the most current version._

This project follows [semantic versioning](https://example.com); so, in particular, since the current version is not yet 1.0, all bets are off in terms of API stability, the structure of error handling, etc. (_That being said, I don't expect too many radical changes on the road to 1.0._)

API documentation to come!


## How to Contribute

Thank you for taking the time to contribute!

There are many ways to contribute in addition to submitting code. Bug reports, feature suggestions, example scripts, additional test cases, a logo for the project, and improvements to documentation are all appreciated.

> All contributors are expected to behave respectfully to other participants in this project regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, caste, color, religion, or sexual identity and orientation.

> Failure to conduct yourself in a civil fashion will result in consequences ranging from a warning to a permanent ban depending on the severity of the infraction.

Each category of contribution below mentions either creating a new issue, or a pull request (PR). If you need assistance with either of these processes, feel free to contact me and I'll be glad to help.

##### Bug Reports and Feature Suggestions

Please submit bug reports and feature suggestions by creating a [new issue](https://github.com/profburke/troll/issues/new). If possible, look for an existing [open issue](https://github.com/profburke/troll/issues) that is related and comment on it.

When creating an issue, the more detail, the better. For bug reports in partciular, try to include at least the following information:

* The application version
* The operating system (macOS, Windows, etc) and version
* The expected behavior
* The observed behavior
* Step-by-step instructions for reproducing the bug

##### Example Scripts and Test Cases

Although as of initial release of this project (September 2021) there is over 80% code coverage, that just goes to show how misleading code coverage can be. There are lots of aspects of this project that are not currently tested adequately from corner cases of the various operators to the precedence rules and operator associativity implemented by the parser. 

I have tried to adopt a testing approach inspired by standard techniques in Golang projects. It is currently somewhat inconsistent and I would very much welcome assistance with cleaning up and improving the testing code.

If that seems daunting to you, following existing patterns and submitting additional test cases, particularly ones that capture corner cases would be appreciated. Feel free to open a PR, or just create an issue with the Troll snippet and expected result.

##### Documentation Improvements

Preferably, submit documentation changes by pull request. However, feel free to post your changes to an [issue](https://github.com/profburke/troll/issues/new) or send them directly to me.

It would be nice to have a site for this project that we could host on Github Pages. Bonus points for a slick logo included on the page! If you have an interest in helping build that, please let me know.

##### Pull Requests

Of course, contributions to the codebase itself are welcome via pull requests.

Please ensure your PR description clearly describes the problem and solution. It should include the relevant issue number, if applicable.


## License

This project is licensed under the BSD 3-Clause License. For details, please read the [LICENSE](https://github.com/profburke/troll/blob/master/LICENSE) file.

