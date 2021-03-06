
#' @importFrom processx run

run_r <- function(bin, args, libpath, repos, stdout, stderr, echo, show,
                  callback, block_callback, spinner, system_profile,
                  user_profile, env, timeout, wd, fail_on_status) {

  ## Temporary wd
  oldwd <- setwd(wd)
  on.exit(setwd(oldwd), add = TRUE)

  ## Temporary profile
  profile <- make_profile(repos)
  on.exit(try(unlink(profile), silent = TRUE), add = TRUE)

  ## Temporary library path
  lib <- paste(libpath, collapse = .Platform$path.sep)

  ## Workaround, R ignores "", need to set to non-existant file
  if (lib == "") lib <- tempfile()

  real_block_callback <-
    if (show) {
      if (is.null(block_callback)) {
        function(x, proc) cat(x)
      } else {
        function(x, proc) { cat(x); block_callback(x) }
      }
    } else if (!is.null(block_callback)) {
      function(x, proc) block_callback(x)
    }

  real_callback <-
    if (!is.null(callback)) function(x, proc) callback(x)

  if (is.na(env["R_LIBS"])) env["R_LIBS"] <- lib
  if (is.na(env["R_LIBS_USER"])) env["R_LIBS_USER"] <- lib
  if (is.na(env["R_LIBS_SITE"])) env["R_LIBS_SITE"] <- lib
  if (!system_profile) env["R_PROFILE"] <- profile
  if (!user_profile) env["R_PROFILE_USER"] <- profile

  out <- with_envvar(
    env,
    run(bin, args = args, stdout_line_callback = real_callback,
        stderr_line_callback = real_callback,
        stdout_callback = real_block_callback,
        stderr_callback = real_block_callback, echo_cmd = echo,
        spinner = spinner, error_on_status = FALSE, timeout = timeout)
  )

  if (!is.null(stdout)) cat(out$stdout, file = stdout)

  ## If the same file is selected for stdout and stderr,
  ## then we need to append here
  if (!is.null(stderr)) {
    append <- ! is.null(stdout) &&
      normalizePath(stdout) == normalizePath(stderr, mustWork = FALSE)
    cat(out$stderr, file = stderr, append = append)
  }

  if (fail_on_status && out$status != 0) stop(make_error(out))

  out
}

make_profile <- function(repos) {
  profile <- tempfile()
  cat("options(repos=", deparse(repos), ")\n", sep = "", file = profile)
  profile
}

make_timeout_error <- function(out) {
  structure(
    list(
      message = "System command timeout",
      stdout = out$stdout,
      stderr = out$stderr,
      status = out$status
    ),
    class = c("system_command_timeout_error",
              "system_command_error", "error", "condition")
  )
}
