
#' Evaluate an expression in another R session
#'
#' @param func Function object to call in the new R process.
#'   The function should be self-contained and only refer to
#'   other functions and use variables explicitly from other packages
#'   using the \code{::} notation. The environment of the function
#'   is set to \code{.GlobalEnv} before passing it to the child process.
#'   Because of this, it is good practice to create an anonymous
#'   function and pass that to \code{callr}, instead of passing
#'   a function object from a (base or other) package. In particular
#'   \preformatted{  r(.libPaths)} does not work, because it is
#'   defined in a special environment, but
#'   \preformatted{  r(function() .libPaths())} works just fine.
#' @param args Arguments to pass to the function. Must be a list.
#' @param libpath The library path.
#' @param repos The \sQuote{repos} option. If \code{NULL}, then no
#'   \code{repos} option is set. This options is only used if
#'   \code{user_profile} or \code{system_profile} is set to \code{FALSE},
#'   as it is set using the system or the user profile.
#' @param stdout The name of the file the standard output of
#'   the child R process will be written to.
#'   If the child process runs with the \code{--slave} option (the default),
#'   then the commands are not echoed and will not be shown
#'   in the standard output. Also note that you need to call `print()`
#'   explicitly to show the output of the command(s).
#' @param stderr The name of the file the standard error of
#'   the child R process will be written to.
#'   In particular \code{message()} sends output to the standard
#'   error. If nothing was sent to the standard error, then this file
#'   will be empty.
#' @param error What to do if the remote process throws an error.
#'   See details below.
#' @param cmdargs Command line arguments to pass to the R process.
#'   Note that \code{c("-f", rscript)} is appended to this, \code{rscript}
#'   is the name of the script file to run. This contains a call to the
#'   supplied function and some error handling code.
#' @param show Logical, whether to show the standard output on the screen
#'   while the child process is running. Note that this is independent
#'   of the \code{stdout} and \code{stderr} arguments. The standard
#'   error is not shown currently.
#' @param callback A function to call for each line of the standard
#'   output and standard error from the child process. It works together
#'   with the \code{show} option; i.e. if \code{show = TRUE}, and a
#'   callback is provided, then the output is shown of the screen, and the
#'   callback is also called.
#' @param block_callback A function to call for each block of the standard
#'   output and standard error. This callback is not line oriented, i.e.
#'   multiple lines or half a line can be passed to the callback.
#' @param spinner Whether to snow a calming spinner on the screen while
#'   the child R session is running. By default it is show if
#'   \code{show = TRUE} and the R session is interactive.
#' @param system_profile Whether to use the system profile file.
#' @param user_profile Whether to use the user's profile file.
#' @param env Environment variables to set for the child process.
#' @param timeout Timeout for the function call to finish. It can be a
#'   \code{\link{difftime}} object, or a real number, meaning seconds.
#'   If the process does not finish before the timeout period expires,
#'   then a `system_command_timeout_error` error is thrown. \code{Inf}
#'   means no timeout.
#' @return Value of the evaluated expression.
#'
#' @section Error handling:
#'
#' \code{callr} handles errors properly. If the child process throws an
#' error, then \code{callr} throws an error with the same error message
#' in the parent process.
#'
#' The \sQuote{error} expert option may be used to specify a different
#' behavior on error. The following values are possible: \itemize{
#' \item \sQuote{error} is the default behavior: throw an error
#'   in the parent, with the same error message. In fact the same
#'   error object is thrown again.
#' \item \sQuote{stack} also throws an error in the parent, but the error
#'   is of a special kind, class \code{callr_condition}, and it contains
#'   both the original error object, and the call stack of the child,
#'   as written out by \code{\link[utils]{dump.frames}}.
#' \item \sQuote{debugger} is similar to \sQuote{stack}, but in addition
#'   to returning the complete call stack, it also start up a debugger
#'   in the child call stack, via \code{\link[utils]{debugger}}.
#' }
#'
#' @family callr functions
#' @examples
#'
#' # Workspace is empty
#' r(function() ls())
#'
#' # library path is the same by default
#' r(function() .libPaths())
#' .libPaths()
#'
#' @export

r <- function(func, args = list(), libpath = .libPaths(),
              repos = getOption("repos"), stdout = NULL, stderr = NULL,
              error = c("error", "stack", "debugger"),
              cmdargs = "--slave", show = FALSE, callback = NULL,
              block_callback = NULL, spinner = show && interactive(),
              system_profile = TRUE, user_profile = TRUE,
              env = character(), timeout = Inf) {

  error <- match.arg(error)
  r_internal(
    func, args, libpath = libpath, repos = repos, stdout = stdout,
    stderr = stderr, error = error, cmdargs = cmdargs, show = show,
    callback = callback, block_callback = block_callback, spinner = spinner,
    system_profile = system_profile, user_profile = user_profile, env = env,
    timeout = timeout
  )
}
