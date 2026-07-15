import 'package:fpdart/fpdart.dart';

import 'failure.dart';

export 'package:fpdart/fpdart.dart'
    show Either, Left, Right, Option, Some, None, TaskEither, Unit, unit;

export 'failure.dart';

/// Synchronous result of a domain operation: `Right(value)` on success,
/// `Left(Failure)` on error. The signature forces both cases to be handled.
typedef Result<T> = Either<Failure, T>;

/// Asynchronous result. Most use cases and repositories return this (Drift and
/// secure storage are async).
typedef FutureResult<T> = Future<Either<Failure, T>>;

/// Composable `fpdart` version, for chaining async operations without nested
/// `try/catch` or intermediate `await`s.
typedef TaskResult<T> = TaskEither<Failure, T>;
