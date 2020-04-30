# Gripen Router

[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

An HTTP router in Crystal, with conflicts detection.

## Features

- Path conflicts detection (an exception is raised when the route is added)
- Flexbility and type safety using generic for path parameters and route actions

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  gripen_router:
    github: grip-framework/gripen-router
```

## License

Copyright (c) 2020 Julien Reichardt - ISC License
