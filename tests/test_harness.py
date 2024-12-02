"""Utility functions for functional tests.

This is imported into test runner scripts in subdirectories under this one.
"""

import argparse
import binascii
import configparser
import hashlib
import os
import random
import re
import shutil
import subprocess
import sys
import termios
import traceback
from typing import Any, Callable, List, Optional, Tuple
from PIL import Image

TEST_DIR = os.path.dirname(os.path.abspath(__file__))

# Read configuration file. This is written by the build system.
# It contains paths to dependencies of the tests, and allows
# them to operate no matter where the build directory is.
config = configparser.ConfigParser()
config.read(os.path.join(TEST_DIR, 'tests.conf'))
default_config = config['DEFAULT']

# A place to dump temporary files. Cleared before each test.
WORK_DIR                = default_config['WORK_DIR']
HARDWARE_INCLUDE_DIR    = default_config['HARDWARE_INCLUDE_DIR']
HARDWARE_GENERAL_DIR    = default_config['HARDWARE_GENERAL_DIR']

ALL_TARGETS     = ['verilator']
DEFAULT_TARGETS = ['verilator']

class TestException(Exception):
    """This exception is raised for test failures"""
    pass

class TerminalStateRestorer(object):
    """This saves and restores the configuration of POSIX terminals.

    The emulator process disables local echo.  If it crashes or
    times out, it can leave the terminal in a bad state. This will
    save and restore the state automatically."""
    def __init__(self):
        self.attrs = None

    def __enter__(self):
        try:
            self.attrs = termios.tcgetattr(sys.stdin.fileno())
        except termios.error:
            # This may throw an exception if the process doesn't
            # have a controlling TTY (continuous integration). In
            # this case, self.attrs will remain None.
            pass

    def __exit__(self, *unused):
        if self.attrs is not None:
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSANOW, self.attrs)

parser = argparse.ArgumentParser()
parser.add_argument('--target', dest='target',
                    help='restrict to only executing tests on this target',
                    nargs=1)
parser.add_argument('--debug', action='store_true',
                    help='enable verbose output to debug test failures')
parser.add_argument('--list', action='store_true',
                    help='list availble tests')
parser.add_argument('--randseed', dest='randseed',
                    help='set verilator random seed', nargs=1)
parser.add_argument('names', nargs=argparse.REMAINDER,
                    help='names of specific tests to run')
test_args = parser.parse_args()
DEBUG = test_args.debug


def find_files(extensions: Tuple[str]) -> List[str]:
    """Find all files in the current directory that have the passed extensions.

    Args:
        extensions
            File extensions, each starting with a dot. For example
            ['.c', '.cpp']

    Returns:
        Filenames.

    Raises:
        Nothing
    """

    return [fname for fname in os.listdir('.') if fname.endswith(extensions)]


def run_test_with_timeout(args: List[str], timeout: float) -> str:
    """Run program specified by args with timeout.

    Args:
        args:
            Arguments to called program the first being the path to the
            executable
        timeout:
            Number of seconds to wait for the program to exit normally
            before throwing exception.

    Returns:
        All data printed to stdout by the process.

    Raises:
        TestException if the test returns a non-zero result or does not
        complete in time.
    """
    process = subprocess.Popen(args, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT)
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        raise TestException('Test timed out')

    if process.poll():
        # Non-zero return code. Probably target program crash.
        raise TestException(
            'Process returned error: ' + output.decode())

    return output.decode()


registered_tests = []

def register_tests(func: Callable[[str, str], None], names: List[str],
                   targets: Optional[List[str]] = None) -> None:
    """Add a list of tests to be run when execute_tests is called.

    This function can be called multiple times, it will append passed
    tests to the existing list.

    Args:
        func:
            A function that will be called for each of the elements
            in the names list.
        names:
            List of tests to run.

    Returns:
        Nothing

    Raises:
        Nothing
     """

    global registered_tests
    if not targets:
        targets = ALL_TARGETS[:]

    registered_tests += [(func, name, targets) for name in names]

COLOR_RED = '[\x1b[31m'
COLOR_GREEN = '[\x1b[32m'
COLOR_NONE = '\x1b[0m]'
OUTPUT_ALIGN = 50

def execute_tests() -> None:
    """Run all registered tests.

    This will print results to stdout. If this fails, it will call sys.exit
    with a non-zero status.

    Args:
        None

    Returns:
        Nothing

    Raises:
        Nothing
    """

    global DEBUG

    if test_args.list:
        for _, param, targets in registered_tests:
            print(param + ': ' + ', '.join(targets))

        return

    if test_args.target:
        targets_to_run = test_args.target
    else:
        targets_to_run = DEFAULT_TARGETS

    # Filter based on names and targets
    if test_args.names:
        tests_to_run = []
        for requested in test_args.names:
            for func, param, targets in registered_tests:
                if param == requested:
                    tests_to_run += [(func, param, targets)]
                    break
            else:
                print('Unknown test ' + requested)
                sys.exit(1)
    else:
        tests_to_run = registered_tests

    test_run_count = 0
    test_pass_count = 0
    failing_tests = []
    for func, param, targets in tests_to_run:
        for target in targets:
            if target not in targets_to_run:
                continue

            label = '{}({})'.format(param, target)
            print(label + (' ' * (OUTPUT_ALIGN - len(label))), end='')
            try:
                # Clean out working directory and re-create
                shutil.rmtree(path=WORK_DIR, ignore_errors=True)
                os.makedirs(WORK_DIR)

                test_run_count += 1
                sys.stdout.flush()
                with TerminalStateRestorer():
                    func(param, target)

                print(COLOR_GREEN + 'PASS' + COLOR_NONE)
                test_pass_count += 1
            except KeyboardInterrupt:
                sys.exit(1)
            except TestException as exc:
                print(COLOR_RED + 'FAIL' + COLOR_NONE)
                failing_tests += [(param, target, exc.args[0])]
            except Exception as exc:  # pylint: disable=W0703
                print(COLOR_RED + 'FAIL' + COLOR_NONE)
                failing_tests += [(param, target, 'Test threw exception:\n' +
                                   traceback.format_exc())]

    if failing_tests:
        print('Failing tests:')
        for name, target, output in failing_tests:
            print('{} ({})'.format(name, target))
            print(output)

    print('{}/{} tests failed'.format(test_run_count - test_pass_count,
                                      test_run_count))
    if failing_tests:
        sys.exit(1)