/******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ 7936:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.issue = exports.issueCommand = void 0;
const os = __importStar(__nccwpck_require__(2037));
const utils_1 = __nccwpck_require__(5781);
/**
 * Commands
 *
 * Command Format:
 *   ::name key=value,key=value::message
 *
 * Examples:
 *   ::warning::This is the message
 *   ::set-env name=MY_VAR::some value
 */
function issueCommand(command, properties, message) {
    const cmd = new Command(command, properties, message);
    process.stdout.write(cmd.toString() + os.EOL);
}
exports.issueCommand = issueCommand;
function issue(name, message = '') {
    issueCommand(name, {}, message);
}
exports.issue = issue;
const CMD_STRING = '::';
class Command {
    constructor(command, properties, message) {
        if (!command) {
            command = 'missing.command';
        }
        this.command = command;
        this.properties = properties;
        this.message = message;
    }
    toString() {
        let cmdStr = CMD_STRING + this.command;
        if (this.properties && Object.keys(this.properties).length > 0) {
            cmdStr += ' ';
            let first = true;
            for (const key in this.properties) {
                if (this.properties.hasOwnProperty(key)) {
                    const val = this.properties[key];
                    if (val) {
                        if (first) {
                            first = false;
                        }
                        else {
                            cmdStr += ',';
                        }
                        cmdStr += `${key}=${escapeProperty(val)}`;
                    }
                }
            }
        }
        cmdStr += `${CMD_STRING}${escapeData(this.message)}`;
        return cmdStr;
    }
}
function escapeData(s) {
    return utils_1.toCommandValue(s)
        .replace(/%/g, '%25')
        .replace(/\r/g, '%0D')
        .replace(/\n/g, '%0A');
}
function escapeProperty(s) {
    return utils_1.toCommandValue(s)
        .replace(/%/g, '%25')
        .replace(/\r/g, '%0D')
        .replace(/\n/g, '%0A')
        .replace(/:/g, '%3A')
        .replace(/,/g, '%2C');
}
//# sourceMappingURL=command.js.map

/***/ }),

/***/ 3539:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.getState = exports.saveState = exports.group = exports.endGroup = exports.startGroup = exports.info = exports.warning = exports.error = exports.debug = exports.isDebug = exports.setFailed = exports.setCommandEcho = exports.setOutput = exports.getBooleanInput = exports.getMultilineInput = exports.getInput = exports.addPath = exports.setSecret = exports.exportVariable = exports.ExitCode = void 0;
const command_1 = __nccwpck_require__(7936);
const file_command_1 = __nccwpck_require__(4041);
const utils_1 = __nccwpck_require__(5781);
const os = __importStar(__nccwpck_require__(2037));
const path = __importStar(__nccwpck_require__(1017));
/**
 * The code to exit an action
 */
var ExitCode;
(function (ExitCode) {
    /**
     * A code indicating that the action was successful
     */
    ExitCode[ExitCode["Success"] = 0] = "Success";
    /**
     * A code indicating that the action was a failure
     */
    ExitCode[ExitCode["Failure"] = 1] = "Failure";
})(ExitCode = exports.ExitCode || (exports.ExitCode = {}));
//-----------------------------------------------------------------------
// Variables
//-----------------------------------------------------------------------
/**
 * Sets env variable for this action and future actions in the job
 * @param name the name of the variable to set
 * @param val the value of the variable. Non-string values will be converted to a string via JSON.stringify
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function exportVariable(name, val) {
    const convertedVal = utils_1.toCommandValue(val);
    process.env[name] = convertedVal;
    const filePath = process.env['GITHUB_ENV'] || '';
    if (filePath) {
        const delimiter = '_GitHubActionsFileCommandDelimeter_';
        const commandValue = `${name}<<${delimiter}${os.EOL}${convertedVal}${os.EOL}${delimiter}`;
        file_command_1.issueCommand('ENV', commandValue);
    }
    else {
        command_1.issueCommand('set-env', { name }, convertedVal);
    }
}
exports.exportVariable = exportVariable;
/**
 * Registers a secret which will get masked from logs
 * @param secret value of the secret
 */
function setSecret(secret) {
    command_1.issueCommand('add-mask', {}, secret);
}
exports.setSecret = setSecret;
/**
 * Prepends inputPath to the PATH (for this action and future actions)
 * @param inputPath
 */
function addPath(inputPath) {
    const filePath = process.env['GITHUB_PATH'] || '';
    if (filePath) {
        file_command_1.issueCommand('PATH', inputPath);
    }
    else {
        command_1.issueCommand('add-path', {}, inputPath);
    }
    process.env['PATH'] = `${inputPath}${path.delimiter}${process.env['PATH']}`;
}
exports.addPath = addPath;
/**
 * Gets the value of an input.
 * Unless trimWhitespace is set to false in InputOptions, the value is also trimmed.
 * Returns an empty string if the value is not defined.
 *
 * @param     name     name of the input to get
 * @param     options  optional. See InputOptions.
 * @returns   string
 */
function getInput(name, options) {
    const val = process.env[`INPUT_${name.replace(/ /g, '_').toUpperCase()}`] || '';
    if (options && options.required && !val) {
        throw new Error(`Input required and not supplied: ${name}`);
    }
    if (options && options.trimWhitespace === false) {
        return val;
    }
    return val.trim();
}
exports.getInput = getInput;
/**
 * Gets the values of an multiline input.  Each value is also trimmed.
 *
 * @param     name     name of the input to get
 * @param     options  optional. See InputOptions.
 * @returns   string[]
 *
 */
function getMultilineInput(name, options) {
    const inputs = getInput(name, options)
        .split('\n')
        .filter(x => x !== '');
    return inputs;
}
exports.getMultilineInput = getMultilineInput;
/**
 * Gets the input value of the boolean type in the YAML 1.2 "core schema" specification.
 * Support boolean input list: `true | True | TRUE | false | False | FALSE` .
 * The return value is also in boolean type.
 * ref: https://yaml.org/spec/1.2/spec.html#id2804923
 *
 * @param     name     name of the input to get
 * @param     options  optional. See InputOptions.
 * @returns   boolean
 */
function getBooleanInput(name, options) {
    const trueValue = ['true', 'True', 'TRUE'];
    const falseValue = ['false', 'False', 'FALSE'];
    const val = getInput(name, options);
    if (trueValue.includes(val))
        return true;
    if (falseValue.includes(val))
        return false;
    throw new TypeError(`Input does not meet YAML 1.2 "Core Schema" specification: ${name}\n` +
        `Support boolean input list: \`true | True | TRUE | false | False | FALSE\``);
}
exports.getBooleanInput = getBooleanInput;
/**
 * Sets the value of an output.
 *
 * @param     name     name of the output to set
 * @param     value    value to store. Non-string values will be converted to a string via JSON.stringify
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function setOutput(name, value) {
    process.stdout.write(os.EOL);
    command_1.issueCommand('set-output', { name }, value);
}
exports.setOutput = setOutput;
/**
 * Enables or disables the echoing of commands into stdout for the rest of the step.
 * Echoing is disabled by default if ACTIONS_STEP_DEBUG is not set.
 *
 */
function setCommandEcho(enabled) {
    command_1.issue('echo', enabled ? 'on' : 'off');
}
exports.setCommandEcho = setCommandEcho;
//-----------------------------------------------------------------------
// Results
//-----------------------------------------------------------------------
/**
 * Sets the action status to failed.
 * When the action exits it will be with an exit code of 1
 * @param message add error issue message
 */
function setFailed(message) {
    process.exitCode = ExitCode.Failure;
    error(message);
}
exports.setFailed = setFailed;
//-----------------------------------------------------------------------
// Logging Commands
//-----------------------------------------------------------------------
/**
 * Gets whether Actions Step Debug is on or not
 */
function isDebug() {
    return process.env['RUNNER_DEBUG'] === '1';
}
exports.isDebug = isDebug;
/**
 * Writes debug message to user log
 * @param message debug message
 */
function debug(message) {
    command_1.issueCommand('debug', {}, message);
}
exports.debug = debug;
/**
 * Adds an error issue
 * @param message error issue message. Errors will be converted to string via toString()
 */
function error(message) {
    command_1.issue('error', message instanceof Error ? message.toString() : message);
}
exports.error = error;
/**
 * Adds an warning issue
 * @param message warning issue message. Errors will be converted to string via toString()
 */
function warning(message) {
    command_1.issue('warning', message instanceof Error ? message.toString() : message);
}
exports.warning = warning;
/**
 * Writes info to log with console.log.
 * @param message info message
 */
function info(message) {
    process.stdout.write(message + os.EOL);
}
exports.info = info;
/**
 * Begin an output group.
 *
 * Output until the next `groupEnd` will be foldable in this group
 *
 * @param name The name of the output group
 */
function startGroup(name) {
    command_1.issue('group', name);
}
exports.startGroup = startGroup;
/**
 * End an output group.
 */
function endGroup() {
    command_1.issue('endgroup');
}
exports.endGroup = endGroup;
/**
 * Wrap an asynchronous function call in a group.
 *
 * Returns the same type as the function itself.
 *
 * @param name The name of the group
 * @param fn The function to wrap in the group
 */
function group(name, fn) {
    return __awaiter(this, void 0, void 0, function* () {
        startGroup(name);
        let result;
        try {
            result = yield fn();
        }
        finally {
            endGroup();
        }
        return result;
    });
}
exports.group = group;
//-----------------------------------------------------------------------
// Wrapper action state
//-----------------------------------------------------------------------
/**
 * Saves state for current action, the state can only be retrieved by this action's post job execution.
 *
 * @param     name     name of the state to store
 * @param     value    value to store. Non-string values will be converted to a string via JSON.stringify
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function saveState(name, value) {
    command_1.issueCommand('save-state', { name }, value);
}
exports.saveState = saveState;
/**
 * Gets the value of an state set by this action's main execution.
 *
 * @param     name     name of the state to get
 * @returns   string
 */
function getState(name) {
    return process.env[`STATE_${name}`] || '';
}
exports.getState = getState;
//# sourceMappingURL=core.js.map

/***/ }),

/***/ 4041:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

// For internal use, subject to change.
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.issueCommand = void 0;
// We use any as a valid input type
/* eslint-disable @typescript-eslint/no-explicit-any */
const fs = __importStar(__nccwpck_require__(7147));
const os = __importStar(__nccwpck_require__(2037));
const utils_1 = __nccwpck_require__(5781);
function issueCommand(command, message) {
    const filePath = process.env[`GITHUB_${command}`];
    if (!filePath) {
        throw new Error(`Unable to find environment variable for file command ${command}`);
    }
    if (!fs.existsSync(filePath)) {
        throw new Error(`Missing file at path: ${filePath}`);
    }
    fs.appendFileSync(filePath, `${utils_1.toCommandValue(message)}${os.EOL}`, {
        encoding: 'utf8'
    });
}
exports.issueCommand = issueCommand;
//# sourceMappingURL=file-command.js.map

/***/ }),

/***/ 5781:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

// We use any as a valid input type
/* eslint-disable @typescript-eslint/no-explicit-any */
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.toCommandValue = void 0;
/**
 * Sanitizes an input into a string so it can be passed into issueCommand safely
 * @param input input to sanitize into a string
 */
function toCommandValue(input) {
    if (input === null || input === undefined) {
        return '';
    }
    else if (typeof input === 'string' || input instanceof String) {
        return input;
    }
    return JSON.stringify(input);
}
exports.toCommandValue = toCommandValue;
//# sourceMappingURL=utils.js.map

/***/ }),

/***/ 9479:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)
const path = __nccwpck_require__(1017)
const mkdirsSync = (__nccwpck_require__(4834).mkdirsSync)
const utimesMillisSync = (__nccwpck_require__(5827).utimesMillisSync)
const stat = __nccwpck_require__(7871)

function copySync (src, dest, opts) {
  if (typeof opts === 'function') {
    opts = { filter: opts }
  }

  opts = opts || {}
  opts.clobber = 'clobber' in opts ? !!opts.clobber : true // default to true for now
  opts.overwrite = 'overwrite' in opts ? !!opts.overwrite : opts.clobber // overwrite falls back to clobber

  // Warn about using preserveTimestamps on 32-bit node
  if (opts.preserveTimestamps && process.arch === 'ia32') {
    console.warn(`fs-extra: Using the preserveTimestamps option in 32-bit node is not recommended;\n
    see https://github.com/jprichardson/node-fs-extra/issues/269`)
  }

  const { srcStat, destStat } = stat.checkPathsSync(src, dest, 'copy', opts)
  stat.checkParentPathsSync(src, srcStat, dest, 'copy')
  return handleFilterAndCopy(destStat, src, dest, opts)
}

function handleFilterAndCopy (destStat, src, dest, opts) {
  if (opts.filter && !opts.filter(src, dest)) return
  const destParent = path.dirname(dest)
  if (!fs.existsSync(destParent)) mkdirsSync(destParent)
  return getStats(destStat, src, dest, opts)
}

function startCopy (destStat, src, dest, opts) {
  if (opts.filter && !opts.filter(src, dest)) return
  return getStats(destStat, src, dest, opts)
}

function getStats (destStat, src, dest, opts) {
  const statSync = opts.dereference ? fs.statSync : fs.lstatSync
  const srcStat = statSync(src)

  if (srcStat.isDirectory()) return onDir(srcStat, destStat, src, dest, opts)
  else if (srcStat.isFile() ||
           srcStat.isCharacterDevice() ||
           srcStat.isBlockDevice()) return onFile(srcStat, destStat, src, dest, opts)
  else if (srcStat.isSymbolicLink()) return onLink(destStat, src, dest, opts)
  else if (srcStat.isSocket()) throw new Error(`Cannot copy a socket file: ${src}`)
  else if (srcStat.isFIFO()) throw new Error(`Cannot copy a FIFO pipe: ${src}`)
  throw new Error(`Unknown file: ${src}`)
}

function onFile (srcStat, destStat, src, dest, opts) {
  if (!destStat) return copyFile(srcStat, src, dest, opts)
  return mayCopyFile(srcStat, src, dest, opts)
}

function mayCopyFile (srcStat, src, dest, opts) {
  if (opts.overwrite) {
    fs.unlinkSync(dest)
    return copyFile(srcStat, src, dest, opts)
  } else if (opts.errorOnExist) {
    throw new Error(`'${dest}' already exists`)
  }
}

function copyFile (srcStat, src, dest, opts) {
  fs.copyFileSync(src, dest)
  if (opts.preserveTimestamps) handleTimestamps(srcStat.mode, src, dest)
  return setDestMode(dest, srcStat.mode)
}

function handleTimestamps (srcMode, src, dest) {
  // Make sure the file is writable before setting the timestamp
  // otherwise open fails with EPERM when invoked with 'r+'
  // (through utimes call)
  if (fileIsNotWritable(srcMode)) makeFileWritable(dest, srcMode)
  return setDestTimestamps(src, dest)
}

function fileIsNotWritable (srcMode) {
  return (srcMode & 0o200) === 0
}

function makeFileWritable (dest, srcMode) {
  return setDestMode(dest, srcMode | 0o200)
}

function setDestMode (dest, srcMode) {
  return fs.chmodSync(dest, srcMode)
}

function setDestTimestamps (src, dest) {
  // The initial srcStat.atime cannot be trusted
  // because it is modified by the read(2) system call
  // (See https://nodejs.org/api/fs.html#fs_stat_time_values)
  const updatedSrcStat = fs.statSync(src)
  return utimesMillisSync(dest, updatedSrcStat.atime, updatedSrcStat.mtime)
}

function onDir (srcStat, destStat, src, dest, opts) {
  if (!destStat) return mkDirAndCopy(srcStat.mode, src, dest, opts)
  return copyDir(src, dest, opts)
}

function mkDirAndCopy (srcMode, src, dest, opts) {
  fs.mkdirSync(dest)
  copyDir(src, dest, opts)
  return setDestMode(dest, srcMode)
}

function copyDir (src, dest, opts) {
  fs.readdirSync(src).forEach(item => copyDirItem(item, src, dest, opts))
}

function copyDirItem (item, src, dest, opts) {
  const srcItem = path.join(src, item)
  const destItem = path.join(dest, item)
  const { destStat } = stat.checkPathsSync(srcItem, destItem, 'copy', opts)
  return startCopy(destStat, srcItem, destItem, opts)
}

function onLink (destStat, src, dest, opts) {
  let resolvedSrc = fs.readlinkSync(src)
  if (opts.dereference) {
    resolvedSrc = path.resolve(process.cwd(), resolvedSrc)
  }

  if (!destStat) {
    return fs.symlinkSync(resolvedSrc, dest)
  } else {
    let resolvedDest
    try {
      resolvedDest = fs.readlinkSync(dest)
    } catch (err) {
      // dest exists and is a regular file or directory,
      // Windows may throw UNKNOWN error. If dest already exists,
      // fs throws error anyway, so no need to guard against it here.
      if (err.code === 'EINVAL' || err.code === 'UNKNOWN') return fs.symlinkSync(resolvedSrc, dest)
      throw err
    }
    if (opts.dereference) {
      resolvedDest = path.resolve(process.cwd(), resolvedDest)
    }
    if (stat.isSrcSubdir(resolvedSrc, resolvedDest)) {
      throw new Error(`Cannot copy '${resolvedSrc}' to a subdirectory of itself, '${resolvedDest}'.`)
    }

    // prevent copy if src is a subdir of dest since unlinking
    // dest in this case would result in removing src contents
    // and therefore a broken symlink would be created.
    if (fs.statSync(dest).isDirectory() && stat.isSrcSubdir(resolvedDest, resolvedSrc)) {
      throw new Error(`Cannot overwrite '${resolvedDest}' with '${resolvedSrc}'.`)
    }
    return copyLink(resolvedSrc, dest)
  }
}

function copyLink (resolvedSrc, dest) {
  fs.unlinkSync(dest)
  return fs.symlinkSync(resolvedSrc, dest)
}

module.exports = copySync


/***/ }),

/***/ 9337:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


module.exports = {
  copySync: __nccwpck_require__(9479)
}


/***/ }),

/***/ 6078:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)
const path = __nccwpck_require__(1017)
const mkdirs = (__nccwpck_require__(4834).mkdirs)
const pathExists = (__nccwpck_require__(2285).pathExists)
const utimesMillis = (__nccwpck_require__(5827).utimesMillis)
const stat = __nccwpck_require__(7871)

function copy (src, dest, opts, cb) {
  if (typeof opts === 'function' && !cb) {
    cb = opts
    opts = {}
  } else if (typeof opts === 'function') {
    opts = { filter: opts }
  }

  cb = cb || function () {}
  opts = opts || {}

  opts.clobber = 'clobber' in opts ? !!opts.clobber : true // default to true for now
  opts.overwrite = 'overwrite' in opts ? !!opts.overwrite : opts.clobber // overwrite falls back to clobber

  // Warn about using preserveTimestamps on 32-bit node
  if (opts.preserveTimestamps && process.arch === 'ia32') {
    console.warn(`fs-extra: Using the preserveTimestamps option in 32-bit node is not recommended;\n
    see https://github.com/jprichardson/node-fs-extra/issues/269`)
  }

  stat.checkPaths(src, dest, 'copy', opts, (err, stats) => {
    if (err) return cb(err)
    const { srcStat, destStat } = stats
    stat.checkParentPaths(src, srcStat, dest, 'copy', err => {
      if (err) return cb(err)
      if (opts.filter) return handleFilter(checkParentDir, destStat, src, dest, opts, cb)
      return checkParentDir(destStat, src, dest, opts, cb)
    })
  })
}

function checkParentDir (destStat, src, dest, opts, cb) {
  const destParent = path.dirname(dest)
  pathExists(destParent, (err, dirExists) => {
    if (err) return cb(err)
    if (dirExists) return getStats(destStat, src, dest, opts, cb)
    mkdirs(destParent, err => {
      if (err) return cb(err)
      return getStats(destStat, src, dest, opts, cb)
    })
  })
}

function handleFilter (onInclude, destStat, src, dest, opts, cb) {
  Promise.resolve(opts.filter(src, dest)).then(include => {
    if (include) return onInclude(destStat, src, dest, opts, cb)
    return cb()
  }, error => cb(error))
}

function startCopy (destStat, src, dest, opts, cb) {
  if (opts.filter) return handleFilter(getStats, destStat, src, dest, opts, cb)
  return getStats(destStat, src, dest, opts, cb)
}

function getStats (destStat, src, dest, opts, cb) {
  const stat = opts.dereference ? fs.stat : fs.lstat
  stat(src, (err, srcStat) => {
    if (err) return cb(err)

    if (srcStat.isDirectory()) return onDir(srcStat, destStat, src, dest, opts, cb)
    else if (srcStat.isFile() ||
             srcStat.isCharacterDevice() ||
             srcStat.isBlockDevice()) return onFile(srcStat, destStat, src, dest, opts, cb)
    else if (srcStat.isSymbolicLink()) return onLink(destStat, src, dest, opts, cb)
    else if (srcStat.isSocket()) return cb(new Error(`Cannot copy a socket file: ${src}`))
    else if (srcStat.isFIFO()) return cb(new Error(`Cannot copy a FIFO pipe: ${src}`))
    return cb(new Error(`Unknown file: ${src}`))
  })
}

function onFile (srcStat, destStat, src, dest, opts, cb) {
  if (!destStat) return copyFile(srcStat, src, dest, opts, cb)
  return mayCopyFile(srcStat, src, dest, opts, cb)
}

function mayCopyFile (srcStat, src, dest, opts, cb) {
  if (opts.overwrite) {
    fs.unlink(dest, err => {
      if (err) return cb(err)
      return copyFile(srcStat, src, dest, opts, cb)
    })
  } else if (opts.errorOnExist) {
    return cb(new Error(`'${dest}' already exists`))
  } else return cb()
}

function copyFile (srcStat, src, dest, opts, cb) {
  fs.copyFile(src, dest, err => {
    if (err) return cb(err)
    if (opts.preserveTimestamps) return handleTimestampsAndMode(srcStat.mode, src, dest, cb)
    return setDestMode(dest, srcStat.mode, cb)
  })
}

function handleTimestampsAndMode (srcMode, src, dest, cb) {
  // Make sure the file is writable before setting the timestamp
  // otherwise open fails with EPERM when invoked with 'r+'
  // (through utimes call)
  if (fileIsNotWritable(srcMode)) {
    return makeFileWritable(dest, srcMode, err => {
      if (err) return cb(err)
      return setDestTimestampsAndMode(srcMode, src, dest, cb)
    })
  }
  return setDestTimestampsAndMode(srcMode, src, dest, cb)
}

function fileIsNotWritable (srcMode) {
  return (srcMode & 0o200) === 0
}

function makeFileWritable (dest, srcMode, cb) {
  return setDestMode(dest, srcMode | 0o200, cb)
}

function setDestTimestampsAndMode (srcMode, src, dest, cb) {
  setDestTimestamps(src, dest, err => {
    if (err) return cb(err)
    return setDestMode(dest, srcMode, cb)
  })
}

function setDestMode (dest, srcMode, cb) {
  return fs.chmod(dest, srcMode, cb)
}

function setDestTimestamps (src, dest, cb) {
  // The initial srcStat.atime cannot be trusted
  // because it is modified by the read(2) system call
  // (See https://nodejs.org/api/fs.html#fs_stat_time_values)
  fs.stat(src, (err, updatedSrcStat) => {
    if (err) return cb(err)
    return utimesMillis(dest, updatedSrcStat.atime, updatedSrcStat.mtime, cb)
  })
}

function onDir (srcStat, destStat, src, dest, opts, cb) {
  if (!destStat) return mkDirAndCopy(srcStat.mode, src, dest, opts, cb)
  return copyDir(src, dest, opts, cb)
}

function mkDirAndCopy (srcMode, src, dest, opts, cb) {
  fs.mkdir(dest, err => {
    if (err) return cb(err)
    copyDir(src, dest, opts, err => {
      if (err) return cb(err)
      return setDestMode(dest, srcMode, cb)
    })
  })
}

function copyDir (src, dest, opts, cb) {
  fs.readdir(src, (err, items) => {
    if (err) return cb(err)
    return copyDirItems(items, src, dest, opts, cb)
  })
}

function copyDirItems (items, src, dest, opts, cb) {
  const item = items.pop()
  if (!item) return cb()
  return copyDirItem(items, item, src, dest, opts, cb)
}

function copyDirItem (items, item, src, dest, opts, cb) {
  const srcItem = path.join(src, item)
  const destItem = path.join(dest, item)
  stat.checkPaths(srcItem, destItem, 'copy', opts, (err, stats) => {
    if (err) return cb(err)
    const { destStat } = stats
    startCopy(destStat, srcItem, destItem, opts, err => {
      if (err) return cb(err)
      return copyDirItems(items, src, dest, opts, cb)
    })
  })
}

function onLink (destStat, src, dest, opts, cb) {
  fs.readlink(src, (err, resolvedSrc) => {
    if (err) return cb(err)
    if (opts.dereference) {
      resolvedSrc = path.resolve(process.cwd(), resolvedSrc)
    }

    if (!destStat) {
      return fs.symlink(resolvedSrc, dest, cb)
    } else {
      fs.readlink(dest, (err, resolvedDest) => {
        if (err) {
          // dest exists and is a regular file or directory,
          // Windows may throw UNKNOWN error. If dest already exists,
          // fs throws error anyway, so no need to guard against it here.
          if (err.code === 'EINVAL' || err.code === 'UNKNOWN') return fs.symlink(resolvedSrc, dest, cb)
          return cb(err)
        }
        if (opts.dereference) {
          resolvedDest = path.resolve(process.cwd(), resolvedDest)
        }
        if (stat.isSrcSubdir(resolvedSrc, resolvedDest)) {
          return cb(new Error(`Cannot copy '${resolvedSrc}' to a subdirectory of itself, '${resolvedDest}'.`))
        }

        // do not copy if src is a subdir of dest since unlinking
        // dest in this case would result in removing src contents
        // and therefore a broken symlink would be created.
        if (destStat.isDirectory() && stat.isSrcSubdir(resolvedDest, resolvedSrc)) {
          return cb(new Error(`Cannot overwrite '${resolvedDest}' with '${resolvedSrc}'.`))
        }
        return copyLink(resolvedSrc, dest, cb)
      })
    }
  })
}

function copyLink (resolvedSrc, dest, cb) {
  fs.unlink(dest, err => {
    if (err) return cb(err)
    return fs.symlink(resolvedSrc, dest, cb)
  })
}

module.exports = copy


/***/ }),

/***/ 2233:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromCallback)
module.exports = {
  copy: u(__nccwpck_require__(6078))
}


/***/ }),

/***/ 5785:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromPromise)
const fs = __nccwpck_require__(8526)
const path = __nccwpck_require__(1017)
const mkdir = __nccwpck_require__(4834)
const remove = __nccwpck_require__(7227)

const emptyDir = u(async function emptyDir (dir) {
  let items
  try {
    items = await fs.readdir(dir)
  } catch {
    return mkdir.mkdirs(dir)
  }

  return Promise.all(items.map(item => remove.remove(path.join(dir, item))))
})

function emptyDirSync (dir) {
  let items
  try {
    items = fs.readdirSync(dir)
  } catch {
    return mkdir.mkdirsSync(dir)
  }

  items.forEach(item => {
    item = path.join(dir, item)
    remove.removeSync(item)
  })
}

module.exports = {
  emptyDirSync,
  emptydirSync: emptyDirSync,
  emptyDir,
  emptydir: emptyDir
}


/***/ }),

/***/ 2402:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromCallback)
const path = __nccwpck_require__(1017)
const fs = __nccwpck_require__(4937)
const mkdir = __nccwpck_require__(4834)

function createFile (file, callback) {
  function makeFile () {
    fs.writeFile(file, '', err => {
      if (err) return callback(err)
      callback()
    })
  }

  fs.stat(file, (err, stats) => { // eslint-disable-line handle-callback-err
    if (!err && stats.isFile()) return callback()
    const dir = path.dirname(file)
    fs.stat(dir, (err, stats) => {
      if (err) {
        // if the directory doesn't exist, make it
        if (err.code === 'ENOENT') {
          return mkdir.mkdirs(dir, err => {
            if (err) return callback(err)
            makeFile()
          })
        }
        return callback(err)
      }

      if (stats.isDirectory()) makeFile()
      else {
        // parent is not a directory
        // This is just to cause an internal ENOTDIR error to be thrown
        fs.readdir(dir, err => {
          if (err) return callback(err)
        })
      }
    })
  })
}

function createFileSync (file) {
  let stats
  try {
    stats = fs.statSync(file)
  } catch {}
  if (stats && stats.isFile()) return

  const dir = path.dirname(file)
  try {
    if (!fs.statSync(dir).isDirectory()) {
      // parent is not a directory
      // This is just to cause an internal ENOTDIR error to be thrown
      fs.readdirSync(dir)
    }
  } catch (err) {
    // If the stat call above failed because the directory doesn't exist, create it
    if (err && err.code === 'ENOENT') mkdir.mkdirsSync(dir)
    else throw err
  }

  fs.writeFileSync(file, '')
}

module.exports = {
  createFile: u(createFile),
  createFileSync
}


/***/ }),

/***/ 308:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const file = __nccwpck_require__(2402)
const link = __nccwpck_require__(7129)
const symlink = __nccwpck_require__(3853)

module.exports = {
  // file
  createFile: file.createFile,
  createFileSync: file.createFileSync,
  ensureFile: file.createFile,
  ensureFileSync: file.createFileSync,
  // link
  createLink: link.createLink,
  createLinkSync: link.createLinkSync,
  ensureLink: link.createLink,
  ensureLinkSync: link.createLinkSync,
  // symlink
  createSymlink: symlink.createSymlink,
  createSymlinkSync: symlink.createSymlinkSync,
  ensureSymlink: symlink.createSymlink,
  ensureSymlinkSync: symlink.createSymlinkSync
}


/***/ }),

/***/ 7129:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromCallback)
const path = __nccwpck_require__(1017)
const fs = __nccwpck_require__(4937)
const mkdir = __nccwpck_require__(4834)
const pathExists = (__nccwpck_require__(2285).pathExists)
const { areIdentical } = __nccwpck_require__(7871)

function createLink (srcpath, dstpath, callback) {
  function makeLink (srcpath, dstpath) {
    fs.link(srcpath, dstpath, err => {
      if (err) return callback(err)
      callback(null)
    })
  }

  fs.lstat(dstpath, (_, dstStat) => {
    fs.lstat(srcpath, (err, srcStat) => {
      if (err) {
        err.message = err.message.replace('lstat', 'ensureLink')
        return callback(err)
      }
      if (dstStat && areIdentical(srcStat, dstStat)) return callback(null)

      const dir = path.dirname(dstpath)
      pathExists(dir, (err, dirExists) => {
        if (err) return callback(err)
        if (dirExists) return makeLink(srcpath, dstpath)
        mkdir.mkdirs(dir, err => {
          if (err) return callback(err)
          makeLink(srcpath, dstpath)
        })
      })
    })
  })
}

function createLinkSync (srcpath, dstpath) {
  let dstStat
  try {
    dstStat = fs.lstatSync(dstpath)
  } catch {}

  try {
    const srcStat = fs.lstatSync(srcpath)
    if (dstStat && areIdentical(srcStat, dstStat)) return
  } catch (err) {
    err.message = err.message.replace('lstat', 'ensureLink')
    throw err
  }

  const dir = path.dirname(dstpath)
  const dirExists = fs.existsSync(dir)
  if (dirExists) return fs.linkSync(srcpath, dstpath)
  mkdir.mkdirsSync(dir)

  return fs.linkSync(srcpath, dstpath)
}

module.exports = {
  createLink: u(createLink),
  createLinkSync
}


/***/ }),

/***/ 1302:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const path = __nccwpck_require__(1017)
const fs = __nccwpck_require__(4937)
const pathExists = (__nccwpck_require__(2285).pathExists)

/**
 * Function that returns two types of paths, one relative to symlink, and one
 * relative to the current working directory. Checks if path is absolute or
 * relative. If the path is relative, this function checks if the path is
 * relative to symlink or relative to current working directory. This is an
 * initiative to find a smarter `srcpath` to supply when building symlinks.
 * This allows you to determine which path to use out of one of three possible
 * types of source paths. The first is an absolute path. This is detected by
 * `path.isAbsolute()`. When an absolute path is provided, it is checked to
 * see if it exists. If it does it's used, if not an error is returned
 * (callback)/ thrown (sync). The other two options for `srcpath` are a
 * relative url. By default Node's `fs.symlink` works by creating a symlink
 * using `dstpath` and expects the `srcpath` to be relative to the newly
 * created symlink. If you provide a `srcpath` that does not exist on the file
 * system it results in a broken symlink. To minimize this, the function
 * checks to see if the 'relative to symlink' source file exists, and if it
 * does it will use it. If it does not, it checks if there's a file that
 * exists that is relative to the current working directory, if does its used.
 * This preserves the expectations of the original fs.symlink spec and adds
 * the ability to pass in `relative to current working direcotry` paths.
 */

function symlinkPaths (srcpath, dstpath, callback) {
  if (path.isAbsolute(srcpath)) {
    return fs.lstat(srcpath, (err) => {
      if (err) {
        err.message = err.message.replace('lstat', 'ensureSymlink')
        return callback(err)
      }
      return callback(null, {
        toCwd: srcpath,
        toDst: srcpath
      })
    })
  } else {
    const dstdir = path.dirname(dstpath)
    const relativeToDst = path.join(dstdir, srcpath)
    return pathExists(relativeToDst, (err, exists) => {
      if (err) return callback(err)
      if (exists) {
        return callback(null, {
          toCwd: relativeToDst,
          toDst: srcpath
        })
      } else {
        return fs.lstat(srcpath, (err) => {
          if (err) {
            err.message = err.message.replace('lstat', 'ensureSymlink')
            return callback(err)
          }
          return callback(null, {
            toCwd: srcpath,
            toDst: path.relative(dstdir, srcpath)
          })
        })
      }
    })
  }
}

function symlinkPathsSync (srcpath, dstpath) {
  let exists
  if (path.isAbsolute(srcpath)) {
    exists = fs.existsSync(srcpath)
    if (!exists) throw new Error('absolute srcpath does not exist')
    return {
      toCwd: srcpath,
      toDst: srcpath
    }
  } else {
    const dstdir = path.dirname(dstpath)
    const relativeToDst = path.join(dstdir, srcpath)
    exists = fs.existsSync(relativeToDst)
    if (exists) {
      return {
        toCwd: relativeToDst,
        toDst: srcpath
      }
    } else {
      exists = fs.existsSync(srcpath)
      if (!exists) throw new Error('relative srcpath does not exist')
      return {
        toCwd: srcpath,
        toDst: path.relative(dstdir, srcpath)
      }
    }
  }
}

module.exports = {
  symlinkPaths,
  symlinkPathsSync
}


/***/ }),

/***/ 1331:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)

function symlinkType (srcpath, type, callback) {
  callback = (typeof type === 'function') ? type : callback
  type = (typeof type === 'function') ? false : type
  if (type) return callback(null, type)
  fs.lstat(srcpath, (err, stats) => {
    if (err) return callback(null, 'file')
    type = (stats && stats.isDirectory()) ? 'dir' : 'file'
    callback(null, type)
  })
}

function symlinkTypeSync (srcpath, type) {
  let stats

  if (type) return type
  try {
    stats = fs.lstatSync(srcpath)
  } catch {
    return 'file'
  }
  return (stats && stats.isDirectory()) ? 'dir' : 'file'
}

module.exports = {
  symlinkType,
  symlinkTypeSync
}


/***/ }),

/***/ 3853:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromCallback)
const path = __nccwpck_require__(1017)
const fs = __nccwpck_require__(8526)
const _mkdirs = __nccwpck_require__(4834)
const mkdirs = _mkdirs.mkdirs
const mkdirsSync = _mkdirs.mkdirsSync

const _symlinkPaths = __nccwpck_require__(1302)
const symlinkPaths = _symlinkPaths.symlinkPaths
const symlinkPathsSync = _symlinkPaths.symlinkPathsSync

const _symlinkType = __nccwpck_require__(1331)
const symlinkType = _symlinkType.symlinkType
const symlinkTypeSync = _symlinkType.symlinkTypeSync

const pathExists = (__nccwpck_require__(2285).pathExists)

const { areIdentical } = __nccwpck_require__(7871)

function createSymlink (srcpath, dstpath, type, callback) {
  callback = (typeof type === 'function') ? type : callback
  type = (typeof type === 'function') ? false : type

  fs.lstat(dstpath, (err, stats) => {
    if (!err && stats.isSymbolicLink()) {
      Promise.all([
        fs.stat(srcpath),
        fs.stat(dstpath)
      ]).then(([srcStat, dstStat]) => {
        if (areIdentical(srcStat, dstStat)) return callback(null)
        _createSymlink(srcpath, dstpath, type, callback)
      })
    } else _createSymlink(srcpath, dstpath, type, callback)
  })
}

function _createSymlink (srcpath, dstpath, type, callback) {
  symlinkPaths(srcpath, dstpath, (err, relative) => {
    if (err) return callback(err)
    srcpath = relative.toDst
    symlinkType(relative.toCwd, type, (err, type) => {
      if (err) return callback(err)
      const dir = path.dirname(dstpath)
      pathExists(dir, (err, dirExists) => {
        if (err) return callback(err)
        if (dirExists) return fs.symlink(srcpath, dstpath, type, callback)
        mkdirs(dir, err => {
          if (err) return callback(err)
          fs.symlink(srcpath, dstpath, type, callback)
        })
      })
    })
  })
}

function createSymlinkSync (srcpath, dstpath, type) {
  let stats
  try {
    stats = fs.lstatSync(dstpath)
  } catch {}
  if (stats && stats.isSymbolicLink()) {
    const srcStat = fs.statSync(srcpath)
    const dstStat = fs.statSync(dstpath)
    if (areIdentical(srcStat, dstStat)) return
  }

  const relative = symlinkPathsSync(srcpath, dstpath)
  srcpath = relative.toDst
  type = symlinkTypeSync(relative.toCwd, type)
  const dir = path.dirname(dstpath)
  const exists = fs.existsSync(dir)
  if (exists) return fs.symlinkSync(srcpath, dstpath, type)
  mkdirsSync(dir)
  return fs.symlinkSync(srcpath, dstpath, type)
}

module.exports = {
  createSymlink: u(createSymlink),
  createSymlinkSync
}


/***/ }),

/***/ 8526:
/***/ ((__unused_webpack_module, exports, __nccwpck_require__) => {

"use strict";

// This is adapted from https://github.com/normalize/mz
// Copyright (c) 2014-2016 Jonathan Ong me@jongleberry.com and Contributors
const u = (__nccwpck_require__(7858).fromCallback)
const fs = __nccwpck_require__(4937)

const api = [
  'access',
  'appendFile',
  'chmod',
  'chown',
  'close',
  'copyFile',
  'fchmod',
  'fchown',
  'fdatasync',
  'fstat',
  'fsync',
  'ftruncate',
  'futimes',
  'lchmod',
  'lchown',
  'link',
  'lstat',
  'mkdir',
  'mkdtemp',
  'open',
  'opendir',
  'readdir',
  'readFile',
  'readlink',
  'realpath',
  'rename',
  'rm',
  'rmdir',
  'stat',
  'symlink',
  'truncate',
  'unlink',
  'utimes',
  'writeFile'
].filter(key => {
  // Some commands are not available on some systems. Ex:
  // fs.opendir was added in Node.js v12.12.0
  // fs.rm was added in Node.js v14.14.0
  // fs.lchown is not available on at least some Linux
  return typeof fs[key] === 'function'
})

// Export cloned fs:
Object.assign(exports, fs)

// Universalify async methods:
api.forEach(method => {
  exports[method] = u(fs[method])
})
exports.realpath.native = u(fs.realpath.native)

// We differ from mz/fs in that we still ship the old, broken, fs.exists()
// since we are a drop-in replacement for the native module
exports.exists = function (filename, callback) {
  if (typeof callback === 'function') {
    return fs.exists(filename, callback)
  }
  return new Promise(resolve => {
    return fs.exists(filename, resolve)
  })
}

// fs.read(), fs.write(), & fs.writev() need special treatment due to multiple callback args

exports.read = function (fd, buffer, offset, length, position, callback) {
  if (typeof callback === 'function') {
    return fs.read(fd, buffer, offset, length, position, callback)
  }
  return new Promise((resolve, reject) => {
    fs.read(fd, buffer, offset, length, position, (err, bytesRead, buffer) => {
      if (err) return reject(err)
      resolve({ bytesRead, buffer })
    })
  })
}

// Function signature can be
// fs.write(fd, buffer[, offset[, length[, position]]], callback)
// OR
// fs.write(fd, string[, position[, encoding]], callback)
// We need to handle both cases, so we use ...args
exports.write = function (fd, buffer, ...args) {
  if (typeof args[args.length - 1] === 'function') {
    return fs.write(fd, buffer, ...args)
  }

  return new Promise((resolve, reject) => {
    fs.write(fd, buffer, ...args, (err, bytesWritten, buffer) => {
      if (err) return reject(err)
      resolve({ bytesWritten, buffer })
    })
  })
}

// fs.writev only available in Node v12.9.0+
if (typeof fs.writev === 'function') {
  // Function signature is
  // s.writev(fd, buffers[, position], callback)
  // We need to handle the optional arg, so we use ...args
  exports.writev = function (fd, buffers, ...args) {
    if (typeof args[args.length - 1] === 'function') {
      return fs.writev(fd, buffers, ...args)
    }

    return new Promise((resolve, reject) => {
      fs.writev(fd, buffers, ...args, (err, bytesWritten, buffers) => {
        if (err) return reject(err)
        resolve({ bytesWritten, buffers })
      })
    })
  }
}


/***/ }),

/***/ 6417:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


module.exports = {
  // Export promiseified graceful-fs:
  ...__nccwpck_require__(8526),
  // Export extra methods:
  ...__nccwpck_require__(9337),
  ...__nccwpck_require__(2233),
  ...__nccwpck_require__(5785),
  ...__nccwpck_require__(308),
  ...__nccwpck_require__(7603),
  ...__nccwpck_require__(4834),
  ...__nccwpck_require__(5060),
  ...__nccwpck_require__(2031),
  ...__nccwpck_require__(4019),
  ...__nccwpck_require__(2285),
  ...__nccwpck_require__(7227)
}


/***/ }),

/***/ 7603:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromPromise)
const jsonFile = __nccwpck_require__(2489)

jsonFile.outputJson = u(__nccwpck_require__(2179))
jsonFile.outputJsonSync = __nccwpck_require__(6046)
// aliases
jsonFile.outputJSON = jsonFile.outputJson
jsonFile.outputJSONSync = jsonFile.outputJsonSync
jsonFile.writeJSON = jsonFile.writeJson
jsonFile.writeJSONSync = jsonFile.writeJsonSync
jsonFile.readJSON = jsonFile.readJson
jsonFile.readJSONSync = jsonFile.readJsonSync

module.exports = jsonFile


/***/ }),

/***/ 2489:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const jsonFile = __nccwpck_require__(8429)

module.exports = {
  // jsonfile exports
  readJson: jsonFile.readFile,
  readJsonSync: jsonFile.readFileSync,
  writeJson: jsonFile.writeFile,
  writeJsonSync: jsonFile.writeFileSync
}


/***/ }),

/***/ 6046:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const { stringify } = __nccwpck_require__(8990)
const { outputFileSync } = __nccwpck_require__(4019)

function outputJsonSync (file, data, options) {
  const str = stringify(data, options)

  outputFileSync(file, str, options)
}

module.exports = outputJsonSync


/***/ }),

/***/ 2179:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const { stringify } = __nccwpck_require__(8990)
const { outputFile } = __nccwpck_require__(4019)

async function outputJson (file, data, options = {}) {
  const str = stringify(data, options)

  await outputFile(file, str, options)
}

module.exports = outputJson


/***/ }),

/***/ 4834:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";

const u = (__nccwpck_require__(7858).fromPromise)
const { makeDir: _makeDir, makeDirSync } = __nccwpck_require__(3712)
const makeDir = u(_makeDir)

module.exports = {
  mkdirs: makeDir,
  mkdirsSync: makeDirSync,
  // alias
  mkdirp: makeDir,
  mkdirpSync: makeDirSync,
  ensureDir: makeDir,
  ensureDirSync: makeDirSync
}


/***/ }),

/***/ 3712:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";

const fs = __nccwpck_require__(8526)
const { checkPath } = __nccwpck_require__(9996)

const getMode = options => {
  const defaults = { mode: 0o777 }
  if (typeof options === 'number') return options
  return ({ ...defaults, ...options }).mode
}

module.exports.makeDir = async (dir, options) => {
  checkPath(dir)

  return fs.mkdir(dir, {
    mode: getMode(options),
    recursive: true
  })
}

module.exports.makeDirSync = (dir, options) => {
  checkPath(dir)

  return fs.mkdirSync(dir, {
    mode: getMode(options),
    recursive: true
  })
}


/***/ }),

/***/ 9996:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";
// Adapted from https://github.com/sindresorhus/make-dir
// Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

const path = __nccwpck_require__(1017)

// https://github.com/nodejs/node/issues/8987
// https://github.com/libuv/libuv/pull/1088
module.exports.checkPath = function checkPath (pth) {
  if (process.platform === 'win32') {
    const pathHasInvalidWinCharacters = /[<>:"|?*]/.test(pth.replace(path.parse(pth).root, ''))

    if (pathHasInvalidWinCharacters) {
      const error = new Error(`Path contains invalid characters: ${pth}`)
      error.code = 'EINVAL'
      throw error
    }
  }
}


/***/ }),

/***/ 5060:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


module.exports = {
  moveSync: __nccwpck_require__(9891)
}


/***/ }),

/***/ 9891:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)
const path = __nccwpck_require__(1017)
const copySync = (__nccwpck_require__(9337).copySync)
const removeSync = (__nccwpck_require__(7227).removeSync)
const mkdirpSync = (__nccwpck_require__(4834).mkdirpSync)
const stat = __nccwpck_require__(7871)

function moveSync (src, dest, opts) {
  opts = opts || {}
  const overwrite = opts.overwrite || opts.clobber || false

  const { srcStat, isChangingCase = false } = stat.checkPathsSync(src, dest, 'move', opts)
  stat.checkParentPathsSync(src, srcStat, dest, 'move')
  if (!isParentRoot(dest)) mkdirpSync(path.dirname(dest))
  return doRename(src, dest, overwrite, isChangingCase)
}

function isParentRoot (dest) {
  const parent = path.dirname(dest)
  const parsedPath = path.parse(parent)
  return parsedPath.root === parent
}

function doRename (src, dest, overwrite, isChangingCase) {
  if (isChangingCase) return rename(src, dest, overwrite)
  if (overwrite) {
    removeSync(dest)
    return rename(src, dest, overwrite)
  }
  if (fs.existsSync(dest)) throw new Error('dest already exists.')
  return rename(src, dest, overwrite)
}

function rename (src, dest, overwrite) {
  try {
    fs.renameSync(src, dest)
  } catch (err) {
    if (err.code !== 'EXDEV') throw err
    return moveAcrossDevice(src, dest, overwrite)
  }
}

function moveAcrossDevice (src, dest, overwrite) {
  const opts = {
    overwrite,
    errorOnExist: true
  }
  copySync(src, dest, opts)
  return removeSync(src)
}

module.exports = moveSync


/***/ }),

/***/ 2031:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromCallback)
module.exports = {
  move: u(__nccwpck_require__(7462))
}


/***/ }),

/***/ 7462:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)
const path = __nccwpck_require__(1017)
const copy = (__nccwpck_require__(2233).copy)
const remove = (__nccwpck_require__(7227).remove)
const mkdirp = (__nccwpck_require__(4834).mkdirp)
const pathExists = (__nccwpck_require__(2285).pathExists)
const stat = __nccwpck_require__(7871)

function move (src, dest, opts, cb) {
  if (typeof opts === 'function') {
    cb = opts
    opts = {}
  }

  const overwrite = opts.overwrite || opts.clobber || false

  stat.checkPaths(src, dest, 'move', opts, (err, stats) => {
    if (err) return cb(err)
    const { srcStat, isChangingCase = false } = stats
    stat.checkParentPaths(src, srcStat, dest, 'move', err => {
      if (err) return cb(err)
      if (isParentRoot(dest)) return doRename(src, dest, overwrite, isChangingCase, cb)
      mkdirp(path.dirname(dest), err => {
        if (err) return cb(err)
        return doRename(src, dest, overwrite, isChangingCase, cb)
      })
    })
  })
}

function isParentRoot (dest) {
  const parent = path.dirname(dest)
  const parsedPath = path.parse(parent)
  return parsedPath.root === parent
}

function doRename (src, dest, overwrite, isChangingCase, cb) {
  if (isChangingCase) return rename(src, dest, overwrite, cb)
  if (overwrite) {
    return remove(dest, err => {
      if (err) return cb(err)
      return rename(src, dest, overwrite, cb)
    })
  }
  pathExists(dest, (err, destExists) => {
    if (err) return cb(err)
    if (destExists) return cb(new Error('dest already exists.'))
    return rename(src, dest, overwrite, cb)
  })
}

function rename (src, dest, overwrite, cb) {
  fs.rename(src, dest, err => {
    if (!err) return cb()
    if (err.code !== 'EXDEV') return cb(err)
    return moveAcrossDevice(src, dest, overwrite, cb)
  })
}

function moveAcrossDevice (src, dest, overwrite, cb) {
  const opts = {
    overwrite,
    errorOnExist: true
  }
  copy(src, dest, opts, err => {
    if (err) return cb(err)
    return remove(src, cb)
  })
}

module.exports = move


/***/ }),

/***/ 4019:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const u = (__nccwpck_require__(7858).fromCallback)
const fs = __nccwpck_require__(4937)
const path = __nccwpck_require__(1017)
const mkdir = __nccwpck_require__(4834)
const pathExists = (__nccwpck_require__(2285).pathExists)

function outputFile (file, data, encoding, callback) {
  if (typeof encoding === 'function') {
    callback = encoding
    encoding = 'utf8'
  }

  const dir = path.dirname(file)
  pathExists(dir, (err, itDoes) => {
    if (err) return callback(err)
    if (itDoes) return fs.writeFile(file, data, encoding, callback)

    mkdir.mkdirs(dir, err => {
      if (err) return callback(err)

      fs.writeFile(file, data, encoding, callback)
    })
  })
}

function outputFileSync (file, ...args) {
  const dir = path.dirname(file)
  if (fs.existsSync(dir)) {
    return fs.writeFileSync(file, ...args)
  }
  mkdir.mkdirsSync(dir)
  fs.writeFileSync(file, ...args)
}

module.exports = {
  outputFile: u(outputFile),
  outputFileSync
}


/***/ }),

/***/ 2285:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";

const u = (__nccwpck_require__(7858).fromPromise)
const fs = __nccwpck_require__(8526)

function pathExists (path) {
  return fs.access(path).then(() => true).catch(() => false)
}

module.exports = {
  pathExists: u(pathExists),
  pathExistsSync: fs.existsSync
}


/***/ }),

/***/ 7227:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)
const u = (__nccwpck_require__(7858).fromCallback)
const rimraf = __nccwpck_require__(8483)

function remove (path, callback) {
  // Node 14.14.0+
  if (fs.rm) return fs.rm(path, { recursive: true, force: true }, callback)
  rimraf(path, callback)
}

function removeSync (path) {
  // Node 14.14.0+
  if (fs.rmSync) return fs.rmSync(path, { recursive: true, force: true })
  rimraf.sync(path)
}

module.exports = {
  remove: u(remove),
  removeSync
}


/***/ }),

/***/ 8483:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)
const path = __nccwpck_require__(1017)
const assert = __nccwpck_require__(9491)

const isWindows = (process.platform === 'win32')

function defaults (options) {
  const methods = [
    'unlink',
    'chmod',
    'stat',
    'lstat',
    'rmdir',
    'readdir'
  ]
  methods.forEach(m => {
    options[m] = options[m] || fs[m]
    m = m + 'Sync'
    options[m] = options[m] || fs[m]
  })

  options.maxBusyTries = options.maxBusyTries || 3
}

function rimraf (p, options, cb) {
  let busyTries = 0

  if (typeof options === 'function') {
    cb = options
    options = {}
  }

  assert(p, 'rimraf: missing path')
  assert.strictEqual(typeof p, 'string', 'rimraf: path should be a string')
  assert.strictEqual(typeof cb, 'function', 'rimraf: callback function required')
  assert(options, 'rimraf: invalid options argument provided')
  assert.strictEqual(typeof options, 'object', 'rimraf: options should be object')

  defaults(options)

  rimraf_(p, options, function CB (er) {
    if (er) {
      if ((er.code === 'EBUSY' || er.code === 'ENOTEMPTY' || er.code === 'EPERM') &&
          busyTries < options.maxBusyTries) {
        busyTries++
        const time = busyTries * 100
        // try again, with the same exact callback as this one.
        return setTimeout(() => rimraf_(p, options, CB), time)
      }

      // already gone
      if (er.code === 'ENOENT') er = null
    }

    cb(er)
  })
}

// Two possible strategies.
// 1. Assume it's a file.  unlink it, then do the dir stuff on EPERM or EISDIR
// 2. Assume it's a directory.  readdir, then do the file stuff on ENOTDIR
//
// Both result in an extra syscall when you guess wrong.  However, there
// are likely far more normal files in the world than directories.  This
// is based on the assumption that a the average number of files per
// directory is >= 1.
//
// If anyone ever complains about this, then I guess the strategy could
// be made configurable somehow.  But until then, YAGNI.
function rimraf_ (p, options, cb) {
  assert(p)
  assert(options)
  assert(typeof cb === 'function')

  // sunos lets the root user unlink directories, which is... weird.
  // so we have to lstat here and make sure it's not a dir.
  options.lstat(p, (er, st) => {
    if (er && er.code === 'ENOENT') {
      return cb(null)
    }

    // Windows can EPERM on stat.  Life is suffering.
    if (er && er.code === 'EPERM' && isWindows) {
      return fixWinEPERM(p, options, er, cb)
    }

    if (st && st.isDirectory()) {
      return rmdir(p, options, er, cb)
    }

    options.unlink(p, er => {
      if (er) {
        if (er.code === 'ENOENT') {
          return cb(null)
        }
        if (er.code === 'EPERM') {
          return (isWindows)
            ? fixWinEPERM(p, options, er, cb)
            : rmdir(p, options, er, cb)
        }
        if (er.code === 'EISDIR') {
          return rmdir(p, options, er, cb)
        }
      }
      return cb(er)
    })
  })
}

function fixWinEPERM (p, options, er, cb) {
  assert(p)
  assert(options)
  assert(typeof cb === 'function')

  options.chmod(p, 0o666, er2 => {
    if (er2) {
      cb(er2.code === 'ENOENT' ? null : er)
    } else {
      options.stat(p, (er3, stats) => {
        if (er3) {
          cb(er3.code === 'ENOENT' ? null : er)
        } else if (stats.isDirectory()) {
          rmdir(p, options, er, cb)
        } else {
          options.unlink(p, cb)
        }
      })
    }
  })
}

function fixWinEPERMSync (p, options, er) {
  let stats

  assert(p)
  assert(options)

  try {
    options.chmodSync(p, 0o666)
  } catch (er2) {
    if (er2.code === 'ENOENT') {
      return
    } else {
      throw er
    }
  }

  try {
    stats = options.statSync(p)
  } catch (er3) {
    if (er3.code === 'ENOENT') {
      return
    } else {
      throw er
    }
  }

  if (stats.isDirectory()) {
    rmdirSync(p, options, er)
  } else {
    options.unlinkSync(p)
  }
}

function rmdir (p, options, originalEr, cb) {
  assert(p)
  assert(options)
  assert(typeof cb === 'function')

  // try to rmdir first, and only readdir on ENOTEMPTY or EEXIST (SunOS)
  // if we guessed wrong, and it's not a directory, then
  // raise the original error.
  options.rmdir(p, er => {
    if (er && (er.code === 'ENOTEMPTY' || er.code === 'EEXIST' || er.code === 'EPERM')) {
      rmkids(p, options, cb)
    } else if (er && er.code === 'ENOTDIR') {
      cb(originalEr)
    } else {
      cb(er)
    }
  })
}

function rmkids (p, options, cb) {
  assert(p)
  assert(options)
  assert(typeof cb === 'function')

  options.readdir(p, (er, files) => {
    if (er) return cb(er)

    let n = files.length
    let errState

    if (n === 0) return options.rmdir(p, cb)

    files.forEach(f => {
      rimraf(path.join(p, f), options, er => {
        if (errState) {
          return
        }
        if (er) return cb(errState = er)
        if (--n === 0) {
          options.rmdir(p, cb)
        }
      })
    })
  })
}

// this looks simpler, and is strictly *faster*, but will
// tie up the JavaScript thread and fail on excessively
// deep directory trees.
function rimrafSync (p, options) {
  let st

  options = options || {}
  defaults(options)

  assert(p, 'rimraf: missing path')
  assert.strictEqual(typeof p, 'string', 'rimraf: path should be a string')
  assert(options, 'rimraf: missing options')
  assert.strictEqual(typeof options, 'object', 'rimraf: options should be object')

  try {
    st = options.lstatSync(p)
  } catch (er) {
    if (er.code === 'ENOENT') {
      return
    }

    // Windows can EPERM on stat.  Life is suffering.
    if (er.code === 'EPERM' && isWindows) {
      fixWinEPERMSync(p, options, er)
    }
  }

  try {
    // sunos lets the root user unlink directories, which is... weird.
    if (st && st.isDirectory()) {
      rmdirSync(p, options, null)
    } else {
      options.unlinkSync(p)
    }
  } catch (er) {
    if (er.code === 'ENOENT') {
      return
    } else if (er.code === 'EPERM') {
      return isWindows ? fixWinEPERMSync(p, options, er) : rmdirSync(p, options, er)
    } else if (er.code !== 'EISDIR') {
      throw er
    }
    rmdirSync(p, options, er)
  }
}

function rmdirSync (p, options, originalEr) {
  assert(p)
  assert(options)

  try {
    options.rmdirSync(p)
  } catch (er) {
    if (er.code === 'ENOTDIR') {
      throw originalEr
    } else if (er.code === 'ENOTEMPTY' || er.code === 'EEXIST' || er.code === 'EPERM') {
      rmkidsSync(p, options)
    } else if (er.code !== 'ENOENT') {
      throw er
    }
  }
}

function rmkidsSync (p, options) {
  assert(p)
  assert(options)
  options.readdirSync(p).forEach(f => rimrafSync(path.join(p, f), options))

  if (isWindows) {
    // We only end up here once we got ENOTEMPTY at least once, and
    // at this point, we are guaranteed to have removed all the kids.
    // So, we know that it won't be ENOENT or ENOTDIR or anything else.
    // try really hard to delete stuff on windows, because it has a
    // PROFOUNDLY annoying habit of not closing handles promptly when
    // files are deleted, resulting in spurious ENOTEMPTY errors.
    const startTime = Date.now()
    do {
      try {
        const ret = options.rmdirSync(p, options)
        return ret
      } catch {}
    } while (Date.now() - startTime < 500) // give up after 500ms
  } else {
    const ret = options.rmdirSync(p, options)
    return ret
  }
}

module.exports = rimraf
rimraf.sync = rimrafSync


/***/ }),

/***/ 7871:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(8526)
const path = __nccwpck_require__(1017)
const util = __nccwpck_require__(3837)

function getStats (src, dest, opts) {
  const statFunc = opts.dereference
    ? (file) => fs.stat(file, { bigint: true })
    : (file) => fs.lstat(file, { bigint: true })
  return Promise.all([
    statFunc(src),
    statFunc(dest).catch(err => {
      if (err.code === 'ENOENT') return null
      throw err
    })
  ]).then(([srcStat, destStat]) => ({ srcStat, destStat }))
}

function getStatsSync (src, dest, opts) {
  let destStat
  const statFunc = opts.dereference
    ? (file) => fs.statSync(file, { bigint: true })
    : (file) => fs.lstatSync(file, { bigint: true })
  const srcStat = statFunc(src)
  try {
    destStat = statFunc(dest)
  } catch (err) {
    if (err.code === 'ENOENT') return { srcStat, destStat: null }
    throw err
  }
  return { srcStat, destStat }
}

function checkPaths (src, dest, funcName, opts, cb) {
  util.callbackify(getStats)(src, dest, opts, (err, stats) => {
    if (err) return cb(err)
    const { srcStat, destStat } = stats

    if (destStat) {
      if (areIdentical(srcStat, destStat)) {
        const srcBaseName = path.basename(src)
        const destBaseName = path.basename(dest)
        if (funcName === 'move' &&
          srcBaseName !== destBaseName &&
          srcBaseName.toLowerCase() === destBaseName.toLowerCase()) {
          return cb(null, { srcStat, destStat, isChangingCase: true })
        }
        return cb(new Error('Source and destination must not be the same.'))
      }
      if (srcStat.isDirectory() && !destStat.isDirectory()) {
        return cb(new Error(`Cannot overwrite non-directory '${dest}' with directory '${src}'.`))
      }
      if (!srcStat.isDirectory() && destStat.isDirectory()) {
        return cb(new Error(`Cannot overwrite directory '${dest}' with non-directory '${src}'.`))
      }
    }

    if (srcStat.isDirectory() && isSrcSubdir(src, dest)) {
      return cb(new Error(errMsg(src, dest, funcName)))
    }
    return cb(null, { srcStat, destStat })
  })
}

function checkPathsSync (src, dest, funcName, opts) {
  const { srcStat, destStat } = getStatsSync(src, dest, opts)

  if (destStat) {
    if (areIdentical(srcStat, destStat)) {
      const srcBaseName = path.basename(src)
      const destBaseName = path.basename(dest)
      if (funcName === 'move' &&
        srcBaseName !== destBaseName &&
        srcBaseName.toLowerCase() === destBaseName.toLowerCase()) {
        return { srcStat, destStat, isChangingCase: true }
      }
      throw new Error('Source and destination must not be the same.')
    }
    if (srcStat.isDirectory() && !destStat.isDirectory()) {
      throw new Error(`Cannot overwrite non-directory '${dest}' with directory '${src}'.`)
    }
    if (!srcStat.isDirectory() && destStat.isDirectory()) {
      throw new Error(`Cannot overwrite directory '${dest}' with non-directory '${src}'.`)
    }
  }

  if (srcStat.isDirectory() && isSrcSubdir(src, dest)) {
    throw new Error(errMsg(src, dest, funcName))
  }
  return { srcStat, destStat }
}

// recursively check if dest parent is a subdirectory of src.
// It works for all file types including symlinks since it
// checks the src and dest inodes. It starts from the deepest
// parent and stops once it reaches the src parent or the root path.
function checkParentPaths (src, srcStat, dest, funcName, cb) {
  const srcParent = path.resolve(path.dirname(src))
  const destParent = path.resolve(path.dirname(dest))
  if (destParent === srcParent || destParent === path.parse(destParent).root) return cb()
  fs.stat(destParent, { bigint: true }, (err, destStat) => {
    if (err) {
      if (err.code === 'ENOENT') return cb()
      return cb(err)
    }
    if (areIdentical(srcStat, destStat)) {
      return cb(new Error(errMsg(src, dest, funcName)))
    }
    return checkParentPaths(src, srcStat, destParent, funcName, cb)
  })
}

function checkParentPathsSync (src, srcStat, dest, funcName) {
  const srcParent = path.resolve(path.dirname(src))
  const destParent = path.resolve(path.dirname(dest))
  if (destParent === srcParent || destParent === path.parse(destParent).root) return
  let destStat
  try {
    destStat = fs.statSync(destParent, { bigint: true })
  } catch (err) {
    if (err.code === 'ENOENT') return
    throw err
  }
  if (areIdentical(srcStat, destStat)) {
    throw new Error(errMsg(src, dest, funcName))
  }
  return checkParentPathsSync(src, srcStat, destParent, funcName)
}

function areIdentical (srcStat, destStat) {
  return destStat.ino && destStat.dev && destStat.ino === srcStat.ino && destStat.dev === srcStat.dev
}

// return true if dest is a subdir of src, otherwise false.
// It only checks the path strings.
function isSrcSubdir (src, dest) {
  const srcArr = path.resolve(src).split(path.sep).filter(i => i)
  const destArr = path.resolve(dest).split(path.sep).filter(i => i)
  return srcArr.reduce((acc, cur, i) => acc && destArr[i] === cur, true)
}

function errMsg (src, dest, funcName) {
  return `Cannot ${funcName} '${src}' to a subdirectory of itself, '${dest}'.`
}

module.exports = {
  checkPaths,
  checkPathsSync,
  checkParentPaths,
  checkParentPathsSync,
  isSrcSubdir,
  areIdentical
}


/***/ }),

/***/ 5827:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

"use strict";


const fs = __nccwpck_require__(4937)

function utimesMillis (path, atime, mtime, callback) {
  // if (!HAS_MILLIS_RES) return fs.utimes(path, atime, mtime, callback)
  fs.open(path, 'r+', (err, fd) => {
    if (err) return callback(err)
    fs.futimes(fd, atime, mtime, futimesErr => {
      fs.close(fd, closeErr => {
        if (callback) callback(futimesErr || closeErr)
      })
    })
  })
}

function utimesMillisSync (path, atime, mtime) {
  const fd = fs.openSync(path, 'r+')
  fs.futimesSync(fd, atime, mtime)
  return fs.closeSync(fd)
}

module.exports = {
  utimesMillis,
  utimesMillisSync
}


/***/ }),

/***/ 2671:
/***/ ((module) => {

"use strict";


module.exports = clone

var getPrototypeOf = Object.getPrototypeOf || function (obj) {
  return obj.__proto__
}

function clone (obj) {
  if (obj === null || typeof obj !== 'object')
    return obj

  if (obj instanceof Object)
    var copy = { __proto__: getPrototypeOf(obj) }
  else
    var copy = Object.create(null)

  Object.getOwnPropertyNames(obj).forEach(function (key) {
    Object.defineProperty(copy, key, Object.getOwnPropertyDescriptor(obj, key))
  })

  return copy
}


/***/ }),

/***/ 8210:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

var fs = __nccwpck_require__(7147)
var polyfills = __nccwpck_require__(7181)
var legacy = __nccwpck_require__(6726)
var clone = __nccwpck_require__(2671)

var util = __nccwpck_require__(3837)

/* istanbul ignore next - node 0.x polyfill */
var gracefulQueue
var previousSymbol

/* istanbul ignore else - node 0.x polyfill */
if (typeof Symbol === 'function' && typeof Symbol.for === 'function') {
  gracefulQueue = Symbol.for('graceful-fs.queue')
  // This is used in testing by future versions
  previousSymbol = Symbol.for('graceful-fs.previous')
} else {
  gracefulQueue = '___graceful-fs.queue'
  previousSymbol = '___graceful-fs.previous'
}

function noop () {}

function publishQueue(context, queue) {
  Object.defineProperty(context, gracefulQueue, {
    get: function() {
      return queue
    }
  })
}

var debug = noop
if (util.debuglog)
  debug = util.debuglog('gfs4')
else if (/\bgfs4\b/i.test(process.env.NODE_DEBUG || ''))
  debug = function() {
    var m = util.format.apply(util, arguments)
    m = 'GFS4: ' + m.split(/\n/).join('\nGFS4: ')
    console.error(m)
  }

// Once time initialization
if (!fs[gracefulQueue]) {
  // This queue can be shared by multiple loaded instances
  var queue = global[gracefulQueue] || []
  publishQueue(fs, queue)

  // Patch fs.close/closeSync to shared queue version, because we need
  // to retry() whenever a close happens *anywhere* in the program.
  // This is essential when multiple graceful-fs instances are
  // in play at the same time.
  fs.close = (function (fs$close) {
    function close (fd, cb) {
      return fs$close.call(fs, fd, function (err) {
        // This function uses the graceful-fs shared queue
        if (!err) {
          resetQueue()
        }

        if (typeof cb === 'function')
          cb.apply(this, arguments)
      })
    }

    Object.defineProperty(close, previousSymbol, {
      value: fs$close
    })
    return close
  })(fs.close)

  fs.closeSync = (function (fs$closeSync) {
    function closeSync (fd) {
      // This function uses the graceful-fs shared queue
      fs$closeSync.apply(fs, arguments)
      resetQueue()
    }

    Object.defineProperty(closeSync, previousSymbol, {
      value: fs$closeSync
    })
    return closeSync
  })(fs.closeSync)

  if (/\bgfs4\b/i.test(process.env.NODE_DEBUG || '')) {
    process.on('exit', function() {
      debug(fs[gracefulQueue])
      __nccwpck_require__(9491).equal(fs[gracefulQueue].length, 0)
    })
  }
}

if (!global[gracefulQueue]) {
  publishQueue(global, fs[gracefulQueue]);
}

module.exports = patch(clone(fs))
if (process.env.TEST_GRACEFUL_FS_GLOBAL_PATCH && !fs.__patched) {
    module.exports = patch(fs)
    fs.__patched = true;
}

function patch (fs) {
  // Everything that references the open() function needs to be in here
  polyfills(fs)
  fs.gracefulify = patch

  fs.createReadStream = createReadStream
  fs.createWriteStream = createWriteStream
  var fs$readFile = fs.readFile
  fs.readFile = readFile
  function readFile (path, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    return go$readFile(path, options, cb)

    function go$readFile (path, options, cb, startTime) {
      return fs$readFile(path, options, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$readFile, [path, options, cb], err, startTime || Date.now(), Date.now()])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
        }
      })
    }
  }

  var fs$writeFile = fs.writeFile
  fs.writeFile = writeFile
  function writeFile (path, data, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    return go$writeFile(path, data, options, cb)

    function go$writeFile (path, data, options, cb, startTime) {
      return fs$writeFile(path, data, options, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$writeFile, [path, data, options, cb], err, startTime || Date.now(), Date.now()])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
        }
      })
    }
  }

  var fs$appendFile = fs.appendFile
  if (fs$appendFile)
    fs.appendFile = appendFile
  function appendFile (path, data, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    return go$appendFile(path, data, options, cb)

    function go$appendFile (path, data, options, cb, startTime) {
      return fs$appendFile(path, data, options, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$appendFile, [path, data, options, cb], err, startTime || Date.now(), Date.now()])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
        }
      })
    }
  }

  var fs$copyFile = fs.copyFile
  if (fs$copyFile)
    fs.copyFile = copyFile
  function copyFile (src, dest, flags, cb) {
    if (typeof flags === 'function') {
      cb = flags
      flags = 0
    }
    return go$copyFile(src, dest, flags, cb)

    function go$copyFile (src, dest, flags, cb, startTime) {
      return fs$copyFile(src, dest, flags, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$copyFile, [src, dest, flags, cb], err, startTime || Date.now(), Date.now()])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
        }
      })
    }
  }

  var fs$readdir = fs.readdir
  fs.readdir = readdir
  var noReaddirOptionVersions = /^v[0-5]\./
  function readdir (path, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    var go$readdir = noReaddirOptionVersions.test(process.version)
      ? function go$readdir (path, options, cb, startTime) {
        return fs$readdir(path, fs$readdirCallback(
          path, options, cb, startTime
        ))
      }
      : function go$readdir (path, options, cb, startTime) {
        return fs$readdir(path, options, fs$readdirCallback(
          path, options, cb, startTime
        ))
      }

    return go$readdir(path, options, cb)

    function fs$readdirCallback (path, options, cb, startTime) {
      return function (err, files) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([
            go$readdir,
            [path, options, cb],
            err,
            startTime || Date.now(),
            Date.now()
          ])
        else {
          if (files && files.sort)
            files.sort()

          if (typeof cb === 'function')
            cb.call(this, err, files)
        }
      }
    }
  }

  if (process.version.substr(0, 4) === 'v0.8') {
    var legStreams = legacy(fs)
    ReadStream = legStreams.ReadStream
    WriteStream = legStreams.WriteStream
  }

  var fs$ReadStream = fs.ReadStream
  if (fs$ReadStream) {
    ReadStream.prototype = Object.create(fs$ReadStream.prototype)
    ReadStream.prototype.open = ReadStream$open
  }

  var fs$WriteStream = fs.WriteStream
  if (fs$WriteStream) {
    WriteStream.prototype = Object.create(fs$WriteStream.prototype)
    WriteStream.prototype.open = WriteStream$open
  }

  Object.defineProperty(fs, 'ReadStream', {
    get: function () {
      return ReadStream
    },
    set: function (val) {
      ReadStream = val
    },
    enumerable: true,
    configurable: true
  })
  Object.defineProperty(fs, 'WriteStream', {
    get: function () {
      return WriteStream
    },
    set: function (val) {
      WriteStream = val
    },
    enumerable: true,
    configurable: true
  })

  // legacy names
  var FileReadStream = ReadStream
  Object.defineProperty(fs, 'FileReadStream', {
    get: function () {
      return FileReadStream
    },
    set: function (val) {
      FileReadStream = val
    },
    enumerable: true,
    configurable: true
  })
  var FileWriteStream = WriteStream
  Object.defineProperty(fs, 'FileWriteStream', {
    get: function () {
      return FileWriteStream
    },
    set: function (val) {
      FileWriteStream = val
    },
    enumerable: true,
    configurable: true
  })

  function ReadStream (path, options) {
    if (this instanceof ReadStream)
      return fs$ReadStream.apply(this, arguments), this
    else
      return ReadStream.apply(Object.create(ReadStream.prototype), arguments)
  }

  function ReadStream$open () {
    var that = this
    open(that.path, that.flags, that.mode, function (err, fd) {
      if (err) {
        if (that.autoClose)
          that.destroy()

        that.emit('error', err)
      } else {
        that.fd = fd
        that.emit('open', fd)
        that.read()
      }
    })
  }

  function WriteStream (path, options) {
    if (this instanceof WriteStream)
      return fs$WriteStream.apply(this, arguments), this
    else
      return WriteStream.apply(Object.create(WriteStream.prototype), arguments)
  }

  function WriteStream$open () {
    var that = this
    open(that.path, that.flags, that.mode, function (err, fd) {
      if (err) {
        that.destroy()
        that.emit('error', err)
      } else {
        that.fd = fd
        that.emit('open', fd)
      }
    })
  }

  function createReadStream (path, options) {
    return new fs.ReadStream(path, options)
  }

  function createWriteStream (path, options) {
    return new fs.WriteStream(path, options)
  }

  var fs$open = fs.open
  fs.open = open
  function open (path, flags, mode, cb) {
    if (typeof mode === 'function')
      cb = mode, mode = null

    return go$open(path, flags, mode, cb)

    function go$open (path, flags, mode, cb, startTime) {
      return fs$open(path, flags, mode, function (err, fd) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$open, [path, flags, mode, cb], err, startTime || Date.now(), Date.now()])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
        }
      })
    }
  }

  return fs
}

function enqueue (elem) {
  debug('ENQUEUE', elem[0].name, elem[1])
  fs[gracefulQueue].push(elem)
  retry()
}

// keep track of the timeout between retry() calls
var retryTimer

// reset the startTime and lastTime to now
// this resets the start of the 60 second overall timeout as well as the
// delay between attempts so that we'll retry these jobs sooner
function resetQueue () {
  var now = Date.now()
  for (var i = 0; i < fs[gracefulQueue].length; ++i) {
    // entries that are only a length of 2 are from an older version, don't
    // bother modifying those since they'll be retried anyway.
    if (fs[gracefulQueue][i].length > 2) {
      fs[gracefulQueue][i][3] = now // startTime
      fs[gracefulQueue][i][4] = now // lastTime
    }
  }
  // call retry to make sure we're actively processing the queue
  retry()
}

function retry () {
  // clear the timer and remove it to help prevent unintended concurrency
  clearTimeout(retryTimer)
  retryTimer = undefined

  if (fs[gracefulQueue].length === 0)
    return

  var elem = fs[gracefulQueue].shift()
  var fn = elem[0]
  var args = elem[1]
  // these items may be unset if they were added by an older graceful-fs
  var err = elem[2]
  var startTime = elem[3]
  var lastTime = elem[4]

  // if we don't have a startTime we have no way of knowing if we've waited
  // long enough, so go ahead and retry this item now
  if (startTime === undefined) {
    debug('RETRY', fn.name, args)
    fn.apply(null, args)
  } else if (Date.now() - startTime >= 60000) {
    // it's been more than 60 seconds total, bail now
    debug('TIMEOUT', fn.name, args)
    var cb = args.pop()
    if (typeof cb === 'function')
      cb.call(null, err)
  } else {
    // the amount of time between the last attempt and right now
    var sinceAttempt = Date.now() - lastTime
    // the amount of time between when we first tried, and when we last tried
    // rounded up to at least 1
    var sinceStart = Math.max(lastTime - startTime, 1)
    // backoff. wait longer than the total time we've been retrying, but only
    // up to a maximum of 100ms
    var desiredDelay = Math.min(sinceStart * 1.2, 100)
    // it's been long enough since the last retry, do it again
    if (sinceAttempt >= desiredDelay) {
      debug('RETRY', fn.name, args)
      fn.apply(null, args.concat([startTime]))
    } else {
      // if we can't do this job yet, push it to the end of the queue
      // and let the next iteration check again
      fs[gracefulQueue].push(elem)
    }
  }

  // schedule our next run if one isn't already scheduled
  if (retryTimer === undefined) {
    retryTimer = setTimeout(retry, 0)
  }
}


/***/ }),

/***/ 6726:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

var Stream = (__nccwpck_require__(2781).Stream)

module.exports = legacy

function legacy (fs) {
  return {
    ReadStream: ReadStream,
    WriteStream: WriteStream
  }

  function ReadStream (path, options) {
    if (!(this instanceof ReadStream)) return new ReadStream(path, options);

    Stream.call(this);

    var self = this;

    this.path = path;
    this.fd = null;
    this.readable = true;
    this.paused = false;

    this.flags = 'r';
    this.mode = 438; /*=0666*/
    this.bufferSize = 64 * 1024;

    options = options || {};

    // Mixin options into this
    var keys = Object.keys(options);
    for (var index = 0, length = keys.length; index < length; index++) {
      var key = keys[index];
      this[key] = options[key];
    }

    if (this.encoding) this.setEncoding(this.encoding);

    if (this.start !== undefined) {
      if ('number' !== typeof this.start) {
        throw TypeError('start must be a Number');
      }
      if (this.end === undefined) {
        this.end = Infinity;
      } else if ('number' !== typeof this.end) {
        throw TypeError('end must be a Number');
      }

      if (this.start > this.end) {
        throw new Error('start must be <= end');
      }

      this.pos = this.start;
    }

    if (this.fd !== null) {
      process.nextTick(function() {
        self._read();
      });
      return;
    }

    fs.open(this.path, this.flags, this.mode, function (err, fd) {
      if (err) {
        self.emit('error', err);
        self.readable = false;
        return;
      }

      self.fd = fd;
      self.emit('open', fd);
      self._read();
    })
  }

  function WriteStream (path, options) {
    if (!(this instanceof WriteStream)) return new WriteStream(path, options);

    Stream.call(this);

    this.path = path;
    this.fd = null;
    this.writable = true;

    this.flags = 'w';
    this.encoding = 'binary';
    this.mode = 438; /*=0666*/
    this.bytesWritten = 0;

    options = options || {};

    // Mixin options into this
    var keys = Object.keys(options);
    for (var index = 0, length = keys.length; index < length; index++) {
      var key = keys[index];
      this[key] = options[key];
    }

    if (this.start !== undefined) {
      if ('number' !== typeof this.start) {
        throw TypeError('start must be a Number');
      }
      if (this.start < 0) {
        throw new Error('start must be >= zero');
      }

      this.pos = this.start;
    }

    this.busy = false;
    this._queue = [];

    if (this.fd === null) {
      this._open = fs.open;
      this._queue.push([this._open, this.path, this.flags, this.mode, undefined]);
      this.flush();
    }
  }
}


/***/ }),

/***/ 7181:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

var constants = __nccwpck_require__(2057)

var origCwd = process.cwd
var cwd = null

var platform = process.env.GRACEFUL_FS_PLATFORM || process.platform

process.cwd = function() {
  if (!cwd)
    cwd = origCwd.call(process)
  return cwd
}
try {
  process.cwd()
} catch (er) {}

// This check is needed until node.js 12 is required
if (typeof process.chdir === 'function') {
  var chdir = process.chdir
  process.chdir = function (d) {
    cwd = null
    chdir.call(process, d)
  }
  if (Object.setPrototypeOf) Object.setPrototypeOf(process.chdir, chdir)
}

module.exports = patch

function patch (fs) {
  // (re-)implement some things that are known busted or missing.

  // lchmod, broken prior to 0.6.2
  // back-port the fix here.
  if (constants.hasOwnProperty('O_SYMLINK') &&
      process.version.match(/^v0\.6\.[0-2]|^v0\.5\./)) {
    patchLchmod(fs)
  }

  // lutimes implementation, or no-op
  if (!fs.lutimes) {
    patchLutimes(fs)
  }

  // https://github.com/isaacs/node-graceful-fs/issues/4
  // Chown should not fail on einval or eperm if non-root.
  // It should not fail on enosys ever, as this just indicates
  // that a fs doesn't support the intended operation.

  fs.chown = chownFix(fs.chown)
  fs.fchown = chownFix(fs.fchown)
  fs.lchown = chownFix(fs.lchown)

  fs.chmod = chmodFix(fs.chmod)
  fs.fchmod = chmodFix(fs.fchmod)
  fs.lchmod = chmodFix(fs.lchmod)

  fs.chownSync = chownFixSync(fs.chownSync)
  fs.fchownSync = chownFixSync(fs.fchownSync)
  fs.lchownSync = chownFixSync(fs.lchownSync)

  fs.chmodSync = chmodFixSync(fs.chmodSync)
  fs.fchmodSync = chmodFixSync(fs.fchmodSync)
  fs.lchmodSync = chmodFixSync(fs.lchmodSync)

  fs.stat = statFix(fs.stat)
  fs.fstat = statFix(fs.fstat)
  fs.lstat = statFix(fs.lstat)

  fs.statSync = statFixSync(fs.statSync)
  fs.fstatSync = statFixSync(fs.fstatSync)
  fs.lstatSync = statFixSync(fs.lstatSync)

  // if lchmod/lchown do not exist, then make them no-ops
  if (fs.chmod && !fs.lchmod) {
    fs.lchmod = function (path, mode, cb) {
      if (cb) process.nextTick(cb)
    }
    fs.lchmodSync = function () {}
  }
  if (fs.chown && !fs.lchown) {
    fs.lchown = function (path, uid, gid, cb) {
      if (cb) process.nextTick(cb)
    }
    fs.lchownSync = function () {}
  }

  // on Windows, A/V software can lock the directory, causing this
  // to fail with an EACCES or EPERM if the directory contains newly
  // created files.  Try again on failure, for up to 60 seconds.

  // Set the timeout this long because some Windows Anti-Virus, such as Parity
  // bit9, may lock files for up to a minute, causing npm package install
  // failures. Also, take care to yield the scheduler. Windows scheduling gives
  // CPU to a busy looping process, which can cause the program causing the lock
  // contention to be starved of CPU by node, so the contention doesn't resolve.
  if (platform === "win32") {
    fs.rename = typeof fs.rename !== 'function' ? fs.rename
    : (function (fs$rename) {
      function rename (from, to, cb) {
        var start = Date.now()
        var backoff = 0;
        fs$rename(from, to, function CB (er) {
          if (er
              && (er.code === "EACCES" || er.code === "EPERM")
              && Date.now() - start < 60000) {
            setTimeout(function() {
              fs.stat(to, function (stater, st) {
                if (stater && stater.code === "ENOENT")
                  fs$rename(from, to, CB);
                else
                  cb(er)
              })
            }, backoff)
            if (backoff < 100)
              backoff += 10;
            return;
          }
          if (cb) cb(er)
        })
      }
      if (Object.setPrototypeOf) Object.setPrototypeOf(rename, fs$rename)
      return rename
    })(fs.rename)
  }

  // if read() returns EAGAIN, then just try it again.
  fs.read = typeof fs.read !== 'function' ? fs.read
  : (function (fs$read) {
    function read (fd, buffer, offset, length, position, callback_) {
      var callback
      if (callback_ && typeof callback_ === 'function') {
        var eagCounter = 0
        callback = function (er, _, __) {
          if (er && er.code === 'EAGAIN' && eagCounter < 10) {
            eagCounter ++
            return fs$read.call(fs, fd, buffer, offset, length, position, callback)
          }
          callback_.apply(this, arguments)
        }
      }
      return fs$read.call(fs, fd, buffer, offset, length, position, callback)
    }

    // This ensures `util.promisify` works as it does for native `fs.read`.
    if (Object.setPrototypeOf) Object.setPrototypeOf(read, fs$read)
    return read
  })(fs.read)

  fs.readSync = typeof fs.readSync !== 'function' ? fs.readSync
  : (function (fs$readSync) { return function (fd, buffer, offset, length, position) {
    var eagCounter = 0
    while (true) {
      try {
        return fs$readSync.call(fs, fd, buffer, offset, length, position)
      } catch (er) {
        if (er.code === 'EAGAIN' && eagCounter < 10) {
          eagCounter ++
          continue
        }
        throw er
      }
    }
  }})(fs.readSync)

  function patchLchmod (fs) {
    fs.lchmod = function (path, mode, callback) {
      fs.open( path
             , constants.O_WRONLY | constants.O_SYMLINK
             , mode
             , function (err, fd) {
        if (err) {
          if (callback) callback(err)
          return
        }
        // prefer to return the chmod error, if one occurs,
        // but still try to close, and report closing errors if they occur.
        fs.fchmod(fd, mode, function (err) {
          fs.close(fd, function(err2) {
            if (callback) callback(err || err2)
          })
        })
      })
    }

    fs.lchmodSync = function (path, mode) {
      var fd = fs.openSync(path, constants.O_WRONLY | constants.O_SYMLINK, mode)

      // prefer to return the chmod error, if one occurs,
      // but still try to close, and report closing errors if they occur.
      var threw = true
      var ret
      try {
        ret = fs.fchmodSync(fd, mode)
        threw = false
      } finally {
        if (threw) {
          try {
            fs.closeSync(fd)
          } catch (er) {}
        } else {
          fs.closeSync(fd)
        }
      }
      return ret
    }
  }

  function patchLutimes (fs) {
    if (constants.hasOwnProperty("O_SYMLINK") && fs.futimes) {
      fs.lutimes = function (path, at, mt, cb) {
        fs.open(path, constants.O_SYMLINK, function (er, fd) {
          if (er) {
            if (cb) cb(er)
            return
          }
          fs.futimes(fd, at, mt, function (er) {
            fs.close(fd, function (er2) {
              if (cb) cb(er || er2)
            })
          })
        })
      }

      fs.lutimesSync = function (path, at, mt) {
        var fd = fs.openSync(path, constants.O_SYMLINK)
        var ret
        var threw = true
        try {
          ret = fs.futimesSync(fd, at, mt)
          threw = false
        } finally {
          if (threw) {
            try {
              fs.closeSync(fd)
            } catch (er) {}
          } else {
            fs.closeSync(fd)
          }
        }
        return ret
      }

    } else if (fs.futimes) {
      fs.lutimes = function (_a, _b, _c, cb) { if (cb) process.nextTick(cb) }
      fs.lutimesSync = function () {}
    }
  }

  function chmodFix (orig) {
    if (!orig) return orig
    return function (target, mode, cb) {
      return orig.call(fs, target, mode, function (er) {
        if (chownErOk(er)) er = null
        if (cb) cb.apply(this, arguments)
      })
    }
  }

  function chmodFixSync (orig) {
    if (!orig) return orig
    return function (target, mode) {
      try {
        return orig.call(fs, target, mode)
      } catch (er) {
        if (!chownErOk(er)) throw er
      }
    }
  }


  function chownFix (orig) {
    if (!orig) return orig
    return function (target, uid, gid, cb) {
      return orig.call(fs, target, uid, gid, function (er) {
        if (chownErOk(er)) er = null
        if (cb) cb.apply(this, arguments)
      })
    }
  }

  function chownFixSync (orig) {
    if (!orig) return orig
    return function (target, uid, gid) {
      try {
        return orig.call(fs, target, uid, gid)
      } catch (er) {
        if (!chownErOk(er)) throw er
      }
    }
  }

  function statFix (orig) {
    if (!orig) return orig
    // Older versions of Node erroneously returned signed integers for
    // uid + gid.
    return function (target, options, cb) {
      if (typeof options === 'function') {
        cb = options
        options = null
      }
      function callback (er, stats) {
        if (stats) {
          if (stats.uid < 0) stats.uid += 0x100000000
          if (stats.gid < 0) stats.gid += 0x100000000
        }
        if (cb) cb.apply(this, arguments)
      }
      return options ? orig.call(fs, target, options, callback)
        : orig.call(fs, target, callback)
    }
  }

  function statFixSync (orig) {
    if (!orig) return orig
    // Older versions of Node erroneously returned signed integers for
    // uid + gid.
    return function (target, options) {
      var stats = options ? orig.call(fs, target, options)
        : orig.call(fs, target)
      if (stats) {
        if (stats.uid < 0) stats.uid += 0x100000000
        if (stats.gid < 0) stats.gid += 0x100000000
      }
      return stats;
    }
  }

  // ENOSYS means that the fs doesn't support the op. Just ignore
  // that, because it doesn't matter.
  //
  // if there's no getuid, or if getuid() is something other
  // than 0, and the error is EINVAL or EPERM, then just ignore
  // it.
  //
  // This specific case is a silent failure in cp, install, tar,
  // and most other unix tools that manage permissions.
  //
  // When running as root, or if other types of errors are
  // encountered, then it's strict.
  function chownErOk (er) {
    if (!er)
      return true

    if (er.code === "ENOSYS")
      return true

    var nonroot = !process.getuid || process.getuid() !== 0
    if (nonroot) {
      if (er.code === "EINVAL" || er.code === "EPERM")
        return true
    }

    return false
  }
}


/***/ }),

/***/ 598:
/***/ ((module) => {

"use strict";


module.exports = clone

var getPrototypeOf = Object.getPrototypeOf || function (obj) {
  return obj.__proto__
}

function clone (obj) {
  if (obj === null || typeof obj !== 'object')
    return obj

  if (obj instanceof Object)
    var copy = { __proto__: getPrototypeOf(obj) }
  else
    var copy = Object.create(null)

  Object.getOwnPropertyNames(obj).forEach(function (key) {
    Object.defineProperty(copy, key, Object.getOwnPropertyDescriptor(obj, key))
  })

  return copy
}


/***/ }),

/***/ 4937:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

var fs = __nccwpck_require__(7147)
var polyfills = __nccwpck_require__(3164)
var legacy = __nccwpck_require__(5813)
var clone = __nccwpck_require__(598)

var util = __nccwpck_require__(3837)

/* istanbul ignore next - node 0.x polyfill */
var gracefulQueue
var previousSymbol

/* istanbul ignore else - node 0.x polyfill */
if (typeof Symbol === 'function' && typeof Symbol.for === 'function') {
  gracefulQueue = Symbol.for('graceful-fs.queue')
  // This is used in testing by future versions
  previousSymbol = Symbol.for('graceful-fs.previous')
} else {
  gracefulQueue = '___graceful-fs.queue'
  previousSymbol = '___graceful-fs.previous'
}

function noop () {}

function publishQueue(context, queue) {
  Object.defineProperty(context, gracefulQueue, {
    get: function() {
      return queue
    }
  })
}

var debug = noop
if (util.debuglog)
  debug = util.debuglog('gfs4')
else if (/\bgfs4\b/i.test(process.env.NODE_DEBUG || ''))
  debug = function() {
    var m = util.format.apply(util, arguments)
    m = 'GFS4: ' + m.split(/\n/).join('\nGFS4: ')
    console.error(m)
  }

// Once time initialization
if (!fs[gracefulQueue]) {
  // This queue can be shared by multiple loaded instances
  var queue = global[gracefulQueue] || []
  publishQueue(fs, queue)

  // Patch fs.close/closeSync to shared queue version, because we need
  // to retry() whenever a close happens *anywhere* in the program.
  // This is essential when multiple graceful-fs instances are
  // in play at the same time.
  fs.close = (function (fs$close) {
    function close (fd, cb) {
      return fs$close.call(fs, fd, function (err) {
        // This function uses the graceful-fs shared queue
        if (!err) {
          retry()
        }

        if (typeof cb === 'function')
          cb.apply(this, arguments)
      })
    }

    Object.defineProperty(close, previousSymbol, {
      value: fs$close
    })
    return close
  })(fs.close)

  fs.closeSync = (function (fs$closeSync) {
    function closeSync (fd) {
      // This function uses the graceful-fs shared queue
      fs$closeSync.apply(fs, arguments)
      retry()
    }

    Object.defineProperty(closeSync, previousSymbol, {
      value: fs$closeSync
    })
    return closeSync
  })(fs.closeSync)

  if (/\bgfs4\b/i.test(process.env.NODE_DEBUG || '')) {
    process.on('exit', function() {
      debug(fs[gracefulQueue])
      __nccwpck_require__(9491).equal(fs[gracefulQueue].length, 0)
    })
  }
}

if (!global[gracefulQueue]) {
  publishQueue(global, fs[gracefulQueue]);
}

module.exports = patch(clone(fs))
if (process.env.TEST_GRACEFUL_FS_GLOBAL_PATCH && !fs.__patched) {
    module.exports = patch(fs)
    fs.__patched = true;
}

function patch (fs) {
  // Everything that references the open() function needs to be in here
  polyfills(fs)
  fs.gracefulify = patch

  fs.createReadStream = createReadStream
  fs.createWriteStream = createWriteStream
  var fs$readFile = fs.readFile
  fs.readFile = readFile
  function readFile (path, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    return go$readFile(path, options, cb)

    function go$readFile (path, options, cb) {
      return fs$readFile(path, options, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$readFile, [path, options, cb]])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
          retry()
        }
      })
    }
  }

  var fs$writeFile = fs.writeFile
  fs.writeFile = writeFile
  function writeFile (path, data, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    return go$writeFile(path, data, options, cb)

    function go$writeFile (path, data, options, cb) {
      return fs$writeFile(path, data, options, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$writeFile, [path, data, options, cb]])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
          retry()
        }
      })
    }
  }

  var fs$appendFile = fs.appendFile
  if (fs$appendFile)
    fs.appendFile = appendFile
  function appendFile (path, data, options, cb) {
    if (typeof options === 'function')
      cb = options, options = null

    return go$appendFile(path, data, options, cb)

    function go$appendFile (path, data, options, cb) {
      return fs$appendFile(path, data, options, function (err) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$appendFile, [path, data, options, cb]])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
          retry()
        }
      })
    }
  }

  var fs$copyFile = fs.copyFile
  if (fs$copyFile)
    fs.copyFile = copyFile
  function copyFile (src, dest, flags, cb) {
    if (typeof flags === 'function') {
      cb = flags
      flags = 0
    }
    return fs$copyFile(src, dest, flags, function (err) {
      if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
        enqueue([fs$copyFile, [src, dest, flags, cb]])
      else {
        if (typeof cb === 'function')
          cb.apply(this, arguments)
        retry()
      }
    })
  }

  var fs$readdir = fs.readdir
  fs.readdir = readdir
  function readdir (path, options, cb) {
    var args = [path]
    if (typeof options !== 'function') {
      args.push(options)
    } else {
      cb = options
    }
    args.push(go$readdir$cb)

    return go$readdir(args)

    function go$readdir$cb (err, files) {
      if (files && files.sort)
        files.sort()

      if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
        enqueue([go$readdir, [args]])

      else {
        if (typeof cb === 'function')
          cb.apply(this, arguments)
        retry()
      }
    }
  }

  function go$readdir (args) {
    return fs$readdir.apply(fs, args)
  }

  if (process.version.substr(0, 4) === 'v0.8') {
    var legStreams = legacy(fs)
    ReadStream = legStreams.ReadStream
    WriteStream = legStreams.WriteStream
  }

  var fs$ReadStream = fs.ReadStream
  if (fs$ReadStream) {
    ReadStream.prototype = Object.create(fs$ReadStream.prototype)
    ReadStream.prototype.open = ReadStream$open
  }

  var fs$WriteStream = fs.WriteStream
  if (fs$WriteStream) {
    WriteStream.prototype = Object.create(fs$WriteStream.prototype)
    WriteStream.prototype.open = WriteStream$open
  }

  Object.defineProperty(fs, 'ReadStream', {
    get: function () {
      return ReadStream
    },
    set: function (val) {
      ReadStream = val
    },
    enumerable: true,
    configurable: true
  })
  Object.defineProperty(fs, 'WriteStream', {
    get: function () {
      return WriteStream
    },
    set: function (val) {
      WriteStream = val
    },
    enumerable: true,
    configurable: true
  })

  // legacy names
  var FileReadStream = ReadStream
  Object.defineProperty(fs, 'FileReadStream', {
    get: function () {
      return FileReadStream
    },
    set: function (val) {
      FileReadStream = val
    },
    enumerable: true,
    configurable: true
  })
  var FileWriteStream = WriteStream
  Object.defineProperty(fs, 'FileWriteStream', {
    get: function () {
      return FileWriteStream
    },
    set: function (val) {
      FileWriteStream = val
    },
    enumerable: true,
    configurable: true
  })

  function ReadStream (path, options) {
    if (this instanceof ReadStream)
      return fs$ReadStream.apply(this, arguments), this
    else
      return ReadStream.apply(Object.create(ReadStream.prototype), arguments)
  }

  function ReadStream$open () {
    var that = this
    open(that.path, that.flags, that.mode, function (err, fd) {
      if (err) {
        if (that.autoClose)
          that.destroy()

        that.emit('error', err)
      } else {
        that.fd = fd
        that.emit('open', fd)
        that.read()
      }
    })
  }

  function WriteStream (path, options) {
    if (this instanceof WriteStream)
      return fs$WriteStream.apply(this, arguments), this
    else
      return WriteStream.apply(Object.create(WriteStream.prototype), arguments)
  }

  function WriteStream$open () {
    var that = this
    open(that.path, that.flags, that.mode, function (err, fd) {
      if (err) {
        that.destroy()
        that.emit('error', err)
      } else {
        that.fd = fd
        that.emit('open', fd)
      }
    })
  }

  function createReadStream (path, options) {
    return new fs.ReadStream(path, options)
  }

  function createWriteStream (path, options) {
    return new fs.WriteStream(path, options)
  }

  var fs$open = fs.open
  fs.open = open
  function open (path, flags, mode, cb) {
    if (typeof mode === 'function')
      cb = mode, mode = null

    return go$open(path, flags, mode, cb)

    function go$open (path, flags, mode, cb) {
      return fs$open(path, flags, mode, function (err, fd) {
        if (err && (err.code === 'EMFILE' || err.code === 'ENFILE'))
          enqueue([go$open, [path, flags, mode, cb]])
        else {
          if (typeof cb === 'function')
            cb.apply(this, arguments)
          retry()
        }
      })
    }
  }

  return fs
}

function enqueue (elem) {
  debug('ENQUEUE', elem[0].name, elem[1])
  fs[gracefulQueue].push(elem)
}

function retry () {
  var elem = fs[gracefulQueue].shift()
  if (elem) {
    debug('RETRY', elem[0].name, elem[1])
    elem[0].apply(null, elem[1])
  }
}


/***/ }),

/***/ 5813:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

var Stream = (__nccwpck_require__(2781).Stream)

module.exports = legacy

function legacy (fs) {
  return {
    ReadStream: ReadStream,
    WriteStream: WriteStream
  }

  function ReadStream (path, options) {
    if (!(this instanceof ReadStream)) return new ReadStream(path, options);

    Stream.call(this);

    var self = this;

    this.path = path;
    this.fd = null;
    this.readable = true;
    this.paused = false;

    this.flags = 'r';
    this.mode = 438; /*=0666*/
    this.bufferSize = 64 * 1024;

    options = options || {};

    // Mixin options into this
    var keys = Object.keys(options);
    for (var index = 0, length = keys.length; index < length; index++) {
      var key = keys[index];
      this[key] = options[key];
    }

    if (this.encoding) this.setEncoding(this.encoding);

    if (this.start !== undefined) {
      if ('number' !== typeof this.start) {
        throw TypeError('start must be a Number');
      }
      if (this.end === undefined) {
        this.end = Infinity;
      } else if ('number' !== typeof this.end) {
        throw TypeError('end must be a Number');
      }

      if (this.start > this.end) {
        throw new Error('start must be <= end');
      }

      this.pos = this.start;
    }

    if (this.fd !== null) {
      process.nextTick(function() {
        self._read();
      });
      return;
    }

    fs.open(this.path, this.flags, this.mode, function (err, fd) {
      if (err) {
        self.emit('error', err);
        self.readable = false;
        return;
      }

      self.fd = fd;
      self.emit('open', fd);
      self._read();
    })
  }

  function WriteStream (path, options) {
    if (!(this instanceof WriteStream)) return new WriteStream(path, options);

    Stream.call(this);

    this.path = path;
    this.fd = null;
    this.writable = true;

    this.flags = 'w';
    this.encoding = 'binary';
    this.mode = 438; /*=0666*/
    this.bytesWritten = 0;

    options = options || {};

    // Mixin options into this
    var keys = Object.keys(options);
    for (var index = 0, length = keys.length; index < length; index++) {
      var key = keys[index];
      this[key] = options[key];
    }

    if (this.start !== undefined) {
      if ('number' !== typeof this.start) {
        throw TypeError('start must be a Number');
      }
      if (this.start < 0) {
        throw new Error('start must be >= zero');
      }

      this.pos = this.start;
    }

    this.busy = false;
    this._queue = [];

    if (this.fd === null) {
      this._open = fs.open;
      this._queue.push([this._open, this.path, this.flags, this.mode, undefined]);
      this.flush();
    }
  }
}


/***/ }),

/***/ 3164:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

var constants = __nccwpck_require__(2057)

var origCwd = process.cwd
var cwd = null

var platform = process.env.GRACEFUL_FS_PLATFORM || process.platform

process.cwd = function() {
  if (!cwd)
    cwd = origCwd.call(process)
  return cwd
}
try {
  process.cwd()
} catch (er) {}

// This check is needed until node.js 12 is required
if (typeof process.chdir === 'function') {
  var chdir = process.chdir
  process.chdir = function (d) {
    cwd = null
    chdir.call(process, d)
  }
  if (Object.setPrototypeOf) Object.setPrototypeOf(process.chdir, chdir)
}

module.exports = patch

function patch (fs) {
  // (re-)implement some things that are known busted or missing.

  // lchmod, broken prior to 0.6.2
  // back-port the fix here.
  if (constants.hasOwnProperty('O_SYMLINK') &&
      process.version.match(/^v0\.6\.[0-2]|^v0\.5\./)) {
    patchLchmod(fs)
  }

  // lutimes implementation, or no-op
  if (!fs.lutimes) {
    patchLutimes(fs)
  }

  // https://github.com/isaacs/node-graceful-fs/issues/4
  // Chown should not fail on einval or eperm if non-root.
  // It should not fail on enosys ever, as this just indicates
  // that a fs doesn't support the intended operation.

  fs.chown = chownFix(fs.chown)
  fs.fchown = chownFix(fs.fchown)
  fs.lchown = chownFix(fs.lchown)

  fs.chmod = chmodFix(fs.chmod)
  fs.fchmod = chmodFix(fs.fchmod)
  fs.lchmod = chmodFix(fs.lchmod)

  fs.chownSync = chownFixSync(fs.chownSync)
  fs.fchownSync = chownFixSync(fs.fchownSync)
  fs.lchownSync = chownFixSync(fs.lchownSync)

  fs.chmodSync = chmodFixSync(fs.chmodSync)
  fs.fchmodSync = chmodFixSync(fs.fchmodSync)
  fs.lchmodSync = chmodFixSync(fs.lchmodSync)

  fs.stat = statFix(fs.stat)
  fs.fstat = statFix(fs.fstat)
  fs.lstat = statFix(fs.lstat)

  fs.statSync = statFixSync(fs.statSync)
  fs.fstatSync = statFixSync(fs.fstatSync)
  fs.lstatSync = statFixSync(fs.lstatSync)

  // if lchmod/lchown do not exist, then make them no-ops
  if (!fs.lchmod) {
    fs.lchmod = function (path, mode, cb) {
      if (cb) process.nextTick(cb)
    }
    fs.lchmodSync = function () {}
  }
  if (!fs.lchown) {
    fs.lchown = function (path, uid, gid, cb) {
      if (cb) process.nextTick(cb)
    }
    fs.lchownSync = function () {}
  }

  // on Windows, A/V software can lock the directory, causing this
  // to fail with an EACCES or EPERM if the directory contains newly
  // created files.  Try again on failure, for up to 60 seconds.

  // Set the timeout this long because some Windows Anti-Virus, such as Parity
  // bit9, may lock files for up to a minute, causing npm package install
  // failures. Also, take care to yield the scheduler. Windows scheduling gives
  // CPU to a busy looping process, which can cause the program causing the lock
  // contention to be starved of CPU by node, so the contention doesn't resolve.
  if (platform === "win32") {
    fs.rename = (function (fs$rename) { return function (from, to, cb) {
      var start = Date.now()
      var backoff = 0;
      fs$rename(from, to, function CB (er) {
        if (er
            && (er.code === "EACCES" || er.code === "EPERM")
            && Date.now() - start < 60000) {
          setTimeout(function() {
            fs.stat(to, function (stater, st) {
              if (stater && stater.code === "ENOENT")
                fs$rename(from, to, CB);
              else
                cb(er)
            })
          }, backoff)
          if (backoff < 100)
            backoff += 10;
          return;
        }
        if (cb) cb(er)
      })
    }})(fs.rename)
  }

  // if read() returns EAGAIN, then just try it again.
  fs.read = (function (fs$read) {
    function read (fd, buffer, offset, length, position, callback_) {
      var callback
      if (callback_ && typeof callback_ === 'function') {
        var eagCounter = 0
        callback = function (er, _, __) {
          if (er && er.code === 'EAGAIN' && eagCounter < 10) {
            eagCounter ++
            return fs$read.call(fs, fd, buffer, offset, length, position, callback)
          }
          callback_.apply(this, arguments)
        }
      }
      return fs$read.call(fs, fd, buffer, offset, length, position, callback)
    }

    // This ensures `util.promisify` works as it does for native `fs.read`.
    if (Object.setPrototypeOf) Object.setPrototypeOf(read, fs$read)
    return read
  })(fs.read)

  fs.readSync = (function (fs$readSync) { return function (fd, buffer, offset, length, position) {
    var eagCounter = 0
    while (true) {
      try {
        return fs$readSync.call(fs, fd, buffer, offset, length, position)
      } catch (er) {
        if (er.code === 'EAGAIN' && eagCounter < 10) {
          eagCounter ++
          continue
        }
        throw er
      }
    }
  }})(fs.readSync)

  function patchLchmod (fs) {
    fs.lchmod = function (path, mode, callback) {
      fs.open( path
             , constants.O_WRONLY | constants.O_SYMLINK
             , mode
             , function (err, fd) {
        if (err) {
          if (callback) callback(err)
          return
        }
        // prefer to return the chmod error, if one occurs,
        // but still try to close, and report closing errors if they occur.
        fs.fchmod(fd, mode, function (err) {
          fs.close(fd, function(err2) {
            if (callback) callback(err || err2)
          })
        })
      })
    }

    fs.lchmodSync = function (path, mode) {
      var fd = fs.openSync(path, constants.O_WRONLY | constants.O_SYMLINK, mode)

      // prefer to return the chmod error, if one occurs,
      // but still try to close, and report closing errors if they occur.
      var threw = true
      var ret
      try {
        ret = fs.fchmodSync(fd, mode)
        threw = false
      } finally {
        if (threw) {
          try {
            fs.closeSync(fd)
          } catch (er) {}
        } else {
          fs.closeSync(fd)
        }
      }
      return ret
    }
  }

  function patchLutimes (fs) {
    if (constants.hasOwnProperty("O_SYMLINK")) {
      fs.lutimes = function (path, at, mt, cb) {
        fs.open(path, constants.O_SYMLINK, function (er, fd) {
          if (er) {
            if (cb) cb(er)
            return
          }
          fs.futimes(fd, at, mt, function (er) {
            fs.close(fd, function (er2) {
              if (cb) cb(er || er2)
            })
          })
        })
      }

      fs.lutimesSync = function (path, at, mt) {
        var fd = fs.openSync(path, constants.O_SYMLINK)
        var ret
        var threw = true
        try {
          ret = fs.futimesSync(fd, at, mt)
          threw = false
        } finally {
          if (threw) {
            try {
              fs.closeSync(fd)
            } catch (er) {}
          } else {
            fs.closeSync(fd)
          }
        }
        return ret
      }

    } else {
      fs.lutimes = function (_a, _b, _c, cb) { if (cb) process.nextTick(cb) }
      fs.lutimesSync = function () {}
    }
  }

  function chmodFix (orig) {
    if (!orig) return orig
    return function (target, mode, cb) {
      return orig.call(fs, target, mode, function (er) {
        if (chownErOk(er)) er = null
        if (cb) cb.apply(this, arguments)
      })
    }
  }

  function chmodFixSync (orig) {
    if (!orig) return orig
    return function (target, mode) {
      try {
        return orig.call(fs, target, mode)
      } catch (er) {
        if (!chownErOk(er)) throw er
      }
    }
  }


  function chownFix (orig) {
    if (!orig) return orig
    return function (target, uid, gid, cb) {
      return orig.call(fs, target, uid, gid, function (er) {
        if (chownErOk(er)) er = null
        if (cb) cb.apply(this, arguments)
      })
    }
  }

  function chownFixSync (orig) {
    if (!orig) return orig
    return function (target, uid, gid) {
      try {
        return orig.call(fs, target, uid, gid)
      } catch (er) {
        if (!chownErOk(er)) throw er
      }
    }
  }

  function statFix (orig) {
    if (!orig) return orig
    // Older versions of Node erroneously returned signed integers for
    // uid + gid.
    return function (target, options, cb) {
      if (typeof options === 'function') {
        cb = options
        options = null
      }
      function callback (er, stats) {
        if (stats) {
          if (stats.uid < 0) stats.uid += 0x100000000
          if (stats.gid < 0) stats.gid += 0x100000000
        }
        if (cb) cb.apply(this, arguments)
      }
      return options ? orig.call(fs, target, options, callback)
        : orig.call(fs, target, callback)
    }
  }

  function statFixSync (orig) {
    if (!orig) return orig
    // Older versions of Node erroneously returned signed integers for
    // uid + gid.
    return function (target, options) {
      var stats = options ? orig.call(fs, target, options)
        : orig.call(fs, target)
      if (stats.uid < 0) stats.uid += 0x100000000
      if (stats.gid < 0) stats.gid += 0x100000000
      return stats;
    }
  }

  // ENOSYS means that the fs doesn't support the op. Just ignore
  // that, because it doesn't matter.
  //
  // if there's no getuid, or if getuid() is something other
  // than 0, and the error is EINVAL or EPERM, then just ignore
  // it.
  //
  // This specific case is a silent failure in cp, install, tar,
  // and most other unix tools that manage permissions.
  //
  // When running as root, or if other types of errors are
  // encountered, then it's strict.
  function chownErOk (er) {
    if (!er)
      return true

    if (er.code === "ENOSYS")
      return true

    var nonroot = !process.getuid || process.getuid() !== 0
    if (nonroot) {
      if (er.code === "EINVAL" || er.code === "EPERM")
        return true
    }

    return false
  }
}


/***/ }),

/***/ 8429:
/***/ ((module, __unused_webpack_exports, __nccwpck_require__) => {

let _fs
try {
  _fs = __nccwpck_require__(8210)
} catch (_) {
  _fs = __nccwpck_require__(7147)
}
const universalify = __nccwpck_require__(7858)
const { stringify, stripBom } = __nccwpck_require__(8990)

async function _readFile (file, options = {}) {
  if (typeof options === 'string') {
    options = { encoding: options }
  }

  const fs = options.fs || _fs

  const shouldThrow = 'throws' in options ? options.throws : true

  let data = await universalify.fromCallback(fs.readFile)(file, options)

  data = stripBom(data)

  let obj
  try {
    obj = JSON.parse(data, options ? options.reviver : null)
  } catch (err) {
    if (shouldThrow) {
      err.message = `${file}: ${err.message}`
      throw err
    } else {
      return null
    }
  }

  return obj
}

const readFile = universalify.fromPromise(_readFile)

function readFileSync (file, options = {}) {
  if (typeof options === 'string') {
    options = { encoding: options }
  }

  const fs = options.fs || _fs

  const shouldThrow = 'throws' in options ? options.throws : true

  try {
    let content = fs.readFileSync(file, options)
    content = stripBom(content)
    return JSON.parse(content, options.reviver)
  } catch (err) {
    if (shouldThrow) {
      err.message = `${file}: ${err.message}`
      throw err
    } else {
      return null
    }
  }
}

async function _writeFile (file, obj, options = {}) {
  const fs = options.fs || _fs

  const str = stringify(obj, options)

  await universalify.fromCallback(fs.writeFile)(file, str, options)
}

const writeFile = universalify.fromPromise(_writeFile)

function writeFileSync (file, obj, options = {}) {
  const fs = options.fs || _fs

  const str = stringify(obj, options)
  // not sure if fs.writeFileSync returns anything, but just in case
  return fs.writeFileSync(file, str, options)
}

const jsonfile = {
  readFile,
  readFileSync,
  writeFile,
  writeFileSync
}

module.exports = jsonfile


/***/ }),

/***/ 8990:
/***/ ((module) => {

function stringify (obj, { EOL = '\n', finalEOL = true, replacer = null, spaces } = {}) {
  const EOF = finalEOL ? EOL : ''
  const str = JSON.stringify(obj, replacer, spaces)

  return str.replace(/\n/g, EOL) + EOF
}

function stripBom (content) {
  // we do this because JSON.parse would convert it to a utf8 string if encoding wasn't specified
  if (Buffer.isBuffer(content)) content = content.toString('utf8')
  return content.replace(/^\uFEFF/, '')
}

module.exports = { stringify, stripBom }


/***/ }),

/***/ 2902:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
// Traversal is stopped if `callback` returns `true`
function reverseTraverse(node, callback) {
    for (const property of Object.values(node)) {
        if (property && typeof property === 'object') {
            if (property instanceof Array) {
                if (property.length > 0 && property[0].type) {
                    for (let i = property.length - 1; i >= 0; i--) {
                        if (reverseTraverse(property[i], callback)) {
                            return true;
                        }
                    }
                }
            }
            else if (property.type) {
                if (reverseTraverse(property, callback)) {
                    return true;
                }
            }
        }
    }
    return callback(node) || false;
}
exports.reverseTraverse = reverseTraverse;
function isRequireCall(node) {
    return (node.type === 'CallExpression' || node.type === 'StringCallExpression')
        && node.base.type === 'Identifier'
        && node.base.name === 'require'
        && (node.type === 'StringCallExpression' || node.arguments.length === 1);
}
function reverseTraverseRequires(node, callback) {
    reverseTraverse(node, node => {
        return isRequireCall(node) && callback(node) === true;
    });
}
exports.reverseTraverseRequires = reverseTraverseRequires;
function isModuleRegistration(expression, registerIdentifier) {
    return expression.type === 'CallExpression'
        && expression.arguments.length === 2
        && expression.base.type === 'Identifier'
        && expression.base.name === registerIdentifier;
}
function iterateModuleRegistrations(chunk, registerIdentifier, callback) {
    const statementCount = chunk.body.length;
    for (let i = 0; i < statementCount; i++) {
        const node = chunk.body[i];
        if (node.type === 'CallStatement') {
            if (isModuleRegistration(node.expression, registerIdentifier)) {
                const nameArgument = node.expression.arguments[0];
                const bodyArgument = node.expression.arguments[1];
                if (nameArgument.type === 'StringLiteral' && bodyArgument.type === 'FunctionDeclaration') {
                    if (callback(nameArgument.value, bodyArgument)) {
                        return;
                    }
                }
            }
        }
    }
}
exports.iterateModuleRegistrations = iterateModuleRegistrations;
//# sourceMappingURL=index.js.map

/***/ }),

/***/ 2656:
/***/ ((__unused_webpack_module, exports, __nccwpck_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
const fs_1 = __nccwpck_require__(7147);
const path_1 = __nccwpck_require__(1017);
const options_1 = __nccwpck_require__(4429);
const process_1 = __nccwpck_require__(1489);
const metadata_1 = __nccwpck_require__(476);
function mergeOptions(options) {
    return Object.assign(Object.assign(Object.assign({}, options_1.defaultOptions), options), { identifiers: Object.assign(Object.assign({}, options_1.defaultOptions.identifiers), options.identifiers) });
}
function bundleModule(module, options) {
    const postprocessedContent = options.postprocess ? options.postprocess(module, options) : module.content;
    const identifiers = options.identifiers;
    return `${identifiers.register}("${module.name}", function(require, _LOADED, ${identifiers.register}, ${identifiers.modules})\n${postprocessedContent}\nend)\n`;
}
function bundleString(lua, options = {}) {
    const realizedOptions = mergeOptions(options);
    const processedModules = {};
    process_1.processModule({
        name: realizedOptions.rootModuleName,
        content: lua,
    }, realizedOptions, processedModules);
    if (Object.keys(processedModules).length === 1 && !realizedOptions.force) {
        return lua;
    }
    const identifiers = realizedOptions.identifiers;
    const runtime = fs_1.readFileSync(__nccwpck_require__.ab + "runtime.lua");
    let bundle = '';
    if (realizedOptions.metadata) {
        bundle += metadata_1.generateMetadata(realizedOptions);
    }
    bundle += `local ${identifiers.require}, ${identifiers.loaded}, ${identifiers.register}, ${identifiers.modules} = ${runtime}`;
    bundle += realizedOptions.isolate ? '(nil)\n' : '(require)\n';
    for (const [name, processedModule] of Object.entries(processedModules)) {
        bundle += bundleModule({
            name,
            content: processedModule.content
        }, realizedOptions);
    }
    bundle += 'return ' + identifiers.require + '("' + realizedOptions.rootModuleName + '")';
    return bundle;
}
exports.bundleString = bundleString;
function bundle(inputFilePath, options = {}) {
    const lua = fs_1.readFileSync(inputFilePath, 'utf8');
    return bundleString(lua, options);
}
exports.bundle = bundle;
//# sourceMappingURL=index.js.map

/***/ }),

/***/ 4429:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.defaultOptions = {
    force: false,
    identifiers: {
        register: '__bundle_register',
        require: '__bundle_require',
        loaded: '__bundle_loaded',
        modules: '__bundle_modules',
    },
    isolate: false,
    luaVersion: '5.3',
    metadata: true,
    paths: ['?', '?.lua'],
    rootModuleName: '__root',
};
//# sourceMappingURL=options.js.map

/***/ }),

/***/ 1489:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
const fs_1 = __nccwpck_require__(7147);
const path_1 = __nccwpck_require__(1017);
const moonsharp_luaparse_1 = __nccwpck_require__(1418);
const ast_1 = __nccwpck_require__(2902);
const metadata_1 = __nccwpck_require__(476);
const ModuleBundlingError_1 = __importDefault(__nccwpck_require__(2750));
const ModuleResolutionError_1 = __importDefault(__nccwpck_require__(7151));
function resolveModule(name, packagePaths) {
    const platformName = name.replace(/\./g, path_1.sep);
    for (const pattern of packagePaths) {
        const path = pattern.replace(/\?/g, platformName);
        if (fs_1.existsSync(path) && fs_1.lstatSync(path).isFile()) {
            return path;
        }
    }
    return null;
}
exports.resolveModule = resolveModule;
function processModule(module, options, processedModules) {
    let content = options.preprocess ? options.preprocess(module, options) : module.content;
    const resolvedModules = [];
    // Ensure we don't attempt to load modules required in nested bundles
    if (!metadata_1.readMetadata(content)) {
        let ast = moonsharp_luaparse_1.parse(content, {
            locations: true,
            luaVersion: options.luaVersion,
            ranges: true,
        });
        ast_1.reverseTraverseRequires(ast, expression => {
            var _a;
            const argument = expression.argument || expression.arguments[0];
            let required = null;
            if (argument.type == 'StringLiteral') {
                required = argument.value;
            }
            else if (options.expressionHandler) {
                required = options.expressionHandler(module, argument);
            }
            if (required) {
                const requiredModuleNames = Array.isArray(required) ? required : [required];
                for (const requiredModule of requiredModuleNames) {
                    const resolvedPath = resolveModule(requiredModule, options.paths);
                    if (!resolvedPath) {
                        const start = (_a = expression.loc) === null || _a === void 0 ? void 0 : _a.start;
                        throw new ModuleResolutionError_1.default(requiredModule, module.name, start.line, start.column);
                    }
                    resolvedModules.push({
                        name: requiredModule,
                        resolvedPath,
                    });
                }
                if (typeof required === "string") {
                    const range = expression.range;
                    const baseRange = expression.base.range;
                    content = content.slice(0, baseRange[1]) + '("' + required + '")' + content.slice(range[1]);
                }
            }
        });
    }
    processedModules[module.name] = Object.assign(Object.assign({}, module), { content });
    for (const resolvedModule of resolvedModules) {
        if (processedModules[resolvedModule.name]) {
            continue;
        }
        try {
            const moduleContent = fs_1.readFileSync(resolvedModule.resolvedPath, 'utf8');
            processModule(Object.assign(Object.assign({}, resolvedModule), { content: moduleContent }), options, processedModules);
        }
        catch (e) {
            throw new ModuleBundlingError_1.default(resolvedModule.name, e);
        }
    }
}
exports.processModule = processModule;
//# sourceMappingURL=process.js.map

/***/ }),

/***/ 2880:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
class MalformedBundleError extends Error {
    constructor(message) {
        super(message);
    }
}
exports["default"] = MalformedBundleError;
//# sourceMappingURL=MalformedBundleError.js.map

/***/ }),

/***/ 2750:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
class ModuleBundlingError extends Error {
    constructor(moduleName, cause) {
        super(`Failed to bundle resolved module ${moduleName}`);
        this.moduleName = moduleName;
        this.cause = cause;
    }
}
exports["default"] = ModuleBundlingError;
//# sourceMappingURL=ModuleBundlingError.js.map

/***/ }),

/***/ 7151:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
class ModuleResolutionError extends Error {
    constructor(moduleName, parentModuleName, line, column) {
        super(`Could not resolve module '${moduleName}' required by '${parentModuleName}' at ${line}:${column}`);
        this.moduleName = moduleName;
        this.parentModuleName = parentModuleName;
        this.line = line;
        this.column = column;
    }
}
exports["default"] = ModuleResolutionError;
//# sourceMappingURL=ModuleResolutionError.js.map

/***/ }),

/***/ 2232:
/***/ ((__unused_webpack_module, exports) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
class NoBundleMetadataError extends Error {
    constructor() {
        super("No metadata found. Only bundles with metadata may be unbundled");
    }
}
exports["default"] = NoBundleMetadataError;
//# sourceMappingURL=NoBundleMetadataError.js.map

/***/ }),

/***/ 1054:
/***/ ((__unused_webpack_module, exports, __nccwpck_require__) => {

"use strict";

Object.defineProperty(exports, "__esModule", ({ value: true }));
var bundle_1 = __nccwpck_require__(2656);
exports.bundle = bundle_1.bundle;
exports.bundleString = bundle_1.bundleString;
var unbundle_1 = __nccwpck_require__(3291);
exports.unbundle = unbundle_1.unbundle;
exports.unbundleString = unbundle_1.unbundleString;
const bundle_2 = __nccwpck_require__(2656);
const unbundle_2 = __nccwpck_require__(3291);
exports["default"] = {
    bundle: bundle_2.bundle,
    bundleString: bundle_2.bundleString,
    unbundle: unbundle_2.unbundle,
    unbundleString: unbundle_2.unbundleString,
};
//# sourceMappingURL=index.js.map

/***/ }),

/***/ 476:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
const package_json_1 = __nccwpck_require__(4131);
const options_1 = __nccwpck_require__(4429);
const MalformedBundleError_1 = __importDefault(__nccwpck_require__(2880));
exports.defaultMetadata = {
    identifiers: options_1.defaultOptions.identifiers,
    luaVersion: options_1.defaultOptions.luaVersion,
    rootModuleName: options_1.defaultOptions.rootModuleName,
    version: package_json_1.version
};
function intersectionDiff(a, subset) {
    const diff = {};
    for (const key of Object.keys(subset)) {
        const setValue = a[key];
        const subsetValue = subset[key];
        if (setValue !== undefined && subsetValue !== undefined && setValue !== subsetValue) {
            if (setValue
                && typeof setValue === 'object'
                && !(setValue instanceof Array)
                && subsetValue
                && typeof subsetValue === 'object'
                && !(subsetValue instanceof Array)) {
                const recursiveDiff = intersectionDiff(setValue, subsetValue);
                if (Object.entries(recursiveDiff).length > 0) {
                    diff[key] = recursiveDiff;
                }
            }
            else {
                diff[key] = subsetValue;
            }
        }
    }
    return diff;
}
function generateMetadata(options) {
    const metadata = intersectionDiff(exports.defaultMetadata, options);
    metadata.version = package_json_1.version;
    return `-- Bundled by luabundle ${JSON.stringify(metadata)}\n`;
}
exports.generateMetadata = generateMetadata;
function parseMetadata(line) {
    const match = line.match(/^-- Bundled by luabundle ({.+})$/);
    if (match) {
        const metadata = JSON.parse(match[1]);
        if (!metadata['version']) {
            throw new MalformedBundleError_1.default('Bundle contains invalid metadata');
        }
        return metadata;
    }
    return null;
}
function readMetadata(lua) {
    // We'll allow users to inject comments and blank lines above our header, but that's it (no code).
    for (let [start, end] = [0, lua.indexOf('\n')]; end !== -1; start = end + 1, end = lua.indexOf('\n', start)) {
        const line = lua.substring(start, end);
        if (line.length > 0 && !line.startsWith("--")) {
            break;
        }
        const metadata = parseMetadata(line);
        if (metadata) {
            return metadata;
        }
    }
    return null;
}
exports.readMetadata = readMetadata;
//# sourceMappingURL=index.js.map

/***/ }),

/***/ 3291:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
const fs_1 = __nccwpck_require__(7147);
const metadata_1 = __nccwpck_require__(476);
const process_1 = __nccwpck_require__(4985);
const MalformedBundleError_1 = __importDefault(__nccwpck_require__(2880));
const NoBundleMetadataError_1 = __importDefault(__nccwpck_require__(2232));
const defaultOptions = {
    rootOnly: false,
};
function mergeOptions(options) {
    return Object.assign(Object.assign({}, defaultOptions), options);
}
function mergeMetadata(metadata) {
    return Object.assign(Object.assign(Object.assign({}, metadata_1.defaultMetadata), metadata), { identifiers: Object.assign(Object.assign({}, metadata_1.defaultMetadata.identifiers), metadata.identifiers) });
}
function unbundleString(lua, options = {}) {
    const metadata = metadata_1.readMetadata(lua);
    if (!metadata) {
        throw new NoBundleMetadataError_1.default();
    }
    const realizedOptions = mergeOptions(options);
    const realizedMetadata = mergeMetadata(metadata);
    const modules = process_1.processModules(lua, realizedMetadata, realizedOptions);
    const rootModule = modules[realizedMetadata.rootModuleName];
    if (!rootModule) {
        throw new MalformedBundleError_1.default(`Root module '${realizedMetadata.rootModuleName}' not found.`);
    }
    return {
        metadata: realizedMetadata,
        modules,
    };
}
exports.unbundleString = unbundleString;
function unbundle(inputFilePath, options = {}) {
    const lua = fs_1.readFileSync(inputFilePath, 'utf8');
    return unbundleString(lua, options);
}
exports.unbundle = unbundle;
//# sourceMappingURL=index.js.map

/***/ }),

/***/ 4985:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
const moonsharp_luaparse_1 = __nccwpck_require__(1418);
const ast_1 = __nccwpck_require__(2902);
const MalformedBundleError_1 = __importDefault(__nccwpck_require__(2880));
function extractModule(lua, name, declaration) {
    if (declaration.parameters.length !== 4) {
        throw new MalformedBundleError_1.default('Module function declaration contained unexpected number of parameters.');
    }
    // luaparse does not included comments in the body, even if you enable
    // comment parsing. However, we don't want to remove user's comments,
    // thus...
    const startIndex = declaration.parameters[3].range[1] + ')\n'.length;
    const endIndex = declaration.range[1] - '\nend'.length;
    const content = lua.substring(startIndex, endIndex);
    return {
        name,
        content,
        start: {
            index: startIndex,
            line: declaration.loc.start.line + 1,
            column: 0,
        },
        end: {
            index: endIndex,
            line: declaration.loc.end.line - 1,
            column: content.length - content.lastIndexOf('\n') - 1
        }
    };
}
function processModules(lua, metadata, options) {
    const modules = {};
    const ast = moonsharp_luaparse_1.parse(lua, {
        locations: true,
        luaVersion: metadata.luaVersion,
        ranges: true,
    });
    ast_1.iterateModuleRegistrations(ast, metadata.identifiers.register, (name, body) => {
        if (options.rootOnly && name !== metadata.rootModuleName) {
            return;
        }
        modules[name] = extractModule(lua, name, body);
        if (options.rootOnly) {
            return true;
        }
    });
    return modules;
}
exports.processModules = processModules;
//# sourceMappingURL=process.js.map

/***/ }),

/***/ 4825:
/***/ (function(module, exports, __nccwpck_require__) {

/* module decorator */ module = __nccwpck_require__.nmd(module);
/*! https://mths.be/luamin v1.0.4 by @mathias */
;(function(root) {

	// Detect free variables `exports`
	var freeExports =  true && exports;

	// Detect free variable `module`
	var freeModule =  true && module &&
		module.exports == freeExports && module;

	// Detect free variable `global`, from Node.js or Browserified code,
	// and use it as `root`
	var freeGlobal = typeof global == 'object' && global;
	if (freeGlobal.global === freeGlobal || freeGlobal.window === freeGlobal) {
		root = freeGlobal;
	}

	/*--------------------------------------------------------------------------*/

	var luaparse = root.luaparse || __nccwpck_require__(1021);
	luaparse.defaultOptions.comments = false;
	luaparse.defaultOptions.scope = true;
	var parse = luaparse.parse;

	var regexAlphaUnderscore = /[a-zA-Z_]/;
	var regexAlphaNumUnderscore = /[a-zA-Z0-9_]/;
	var regexDigits = /[0-9]/;

	// http://www.lua.org/manual/5.2/manual.html#3.4.7
	// http://www.lua.org/source/5.2/lparser.c.html#priority
	var PRECEDENCE = {
		'or': 1,
		'and': 2,
		'<': 3, '>': 3, '<=': 3, '>=': 3, '~=': 3, '==': 3,
		'..': 5,
		'+': 6, '-': 6, // binary -
		'*': 7, '/': 7, '%': 7,
		'unarynot': 8, 'unary#': 8, 'unary-': 8, // unary -
		'^': 10
	};

	var IDENTIFIER_PARTS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a',
		'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
		'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'A', 'B', 'C', 'D', 'E',
		'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
		'U', 'V', 'W', 'X', 'Y', 'Z', '_'];
	var IDENTIFIER_PARTS_MAX = IDENTIFIER_PARTS.length - 1;

	var each = function(array, fn) {
		var index = -1;
		var length = array.length;
		var max = length - 1;
		while (++index < length) {
			fn(array[index], index < max);
		}
	};

	var indexOf = function(array, value) {
		var index = -1;
		var length = array.length;
		while (++index < length) {
			if (array[index] == value) {
				return index;
			}
		}
	};

	var hasOwnProperty = {}.hasOwnProperty;
	var extend = function(destination, source) {
		var key;
		if (source) {
			for (key in source) {
				if (hasOwnProperty.call(source, key)) {
					destination[key] = source[key];
				}
			}
		}
		return destination;
	};

	var generateZeroes = function(length) {
		var zero = '0';
		var result = '';
		if (length < 1) {
			return result;
		}
		if (length == 1) {
			return zero;
		}
		while (length) {
			if (length & 1) {
				result += zero;
			}
			if (length >>= 1) {
				zero += zero;
			}
		}
		return result;
	};

	// http://www.lua.org/manual/5.2/manual.html#3.1
	function isKeyword(id) {
		switch (id.length) {
			case 2:
				return 'do' == id || 'if' == id || 'in' == id || 'or' == id;
			case 3:
				return 'and' == id || 'end' == id || 'for' == id || 'nil' == id ||
					'not' == id;
			case 4:
				return 'else' == id || 'goto' == id || 'then' == id || 'true' == id;
			case 5:
				return 'break' == id || 'false' == id || 'local' == id ||
					'until' == id || 'while' == id;
			case 6:
				return 'elseif' == id || 'repeat' == id || 'return' == id;
			case 8:
				return 'function' == id;
		}
		return false;
	}

	var currentIdentifier;
	var identifierMap;
	var identifiersInUse;
	var generateIdentifier = function(originalName) {
		// Preserve `self` in methods
		if (originalName == 'self') {
			return originalName;
		}

		if (hasOwnProperty.call(identifierMap, originalName)) {
			return identifierMap[originalName];
		}
		var length = currentIdentifier.length;
		var position = length - 1;
		var character;
		var index;
		while (position >= 0) {
			character = currentIdentifier.charAt(position);
			index = indexOf(IDENTIFIER_PARTS, character);
			if (index != IDENTIFIER_PARTS_MAX) {
				currentIdentifier = currentIdentifier.substring(0, position) +
					IDENTIFIER_PARTS[index + 1] + generateZeroes(length - (position + 1));
				if (
					isKeyword(currentIdentifier) ||
					indexOf(identifiersInUse, currentIdentifier) > -1
				) {
					return generateIdentifier(originalName);
				}
				identifierMap[originalName] = currentIdentifier;
				return currentIdentifier;
			}
			--position;
		}
		currentIdentifier = 'a' + generateZeroes(length);
		if (indexOf(identifiersInUse, currentIdentifier) > -1) {
			return generateIdentifier(originalName);
		}
		identifierMap[originalName] = currentIdentifier;
		return currentIdentifier;
	};

	/*--------------------------------------------------------------------------*/

	var joinStatements = function(a, b, separator) {
		separator || (separator = ' ');

		var lastCharA = a.slice(-1);
		var firstCharB = b.charAt(0);

		if (lastCharA == '' || firstCharB == '') {
			return a + b;
		}
		if (regexAlphaUnderscore.test(lastCharA)) {
			if (regexAlphaNumUnderscore.test(firstCharB)) {
				// e.g. `while` + `1`
				// e.g. `local a` + `local b`
				return a + separator + b;
			} else {
				// e.g. `not` + `(2>3 or 3<2)`
				// e.g. `x` + `^`
				return a + b;
			}
		}
		if (regexDigits.test(lastCharA)) {
			if (
				firstCharB == '(' ||
				!(firstCharB == '.' ||
				regexAlphaUnderscore.test(firstCharB))
			) {
				// e.g. `1` + `+`
				// e.g. `1` + `==`
				return a + b;
			} else {
				// e.g. `1` + `..`
				// e.g. `1` + `and`
				return a + separator + b;
			}
		}
		if (lastCharA == firstCharB && lastCharA == '-') {
			// e.g. `1-` + `-2`
			return a + separator + b;
		}
		return a + b;
	};

	var formatBase = function(base) {
		var result = '';
		var type = base.type;
		var needsParens = base.inParens && (
			type == 'BinaryExpression' ||
			type == 'FunctionDeclaration' ||
			type == 'TableConstructorExpression' ||
			type == 'LogicalExpression' ||
			type == 'StringLiteral'
		);
		if (needsParens) {
			result += '(';
		}
		result += formatExpression(base);
		if (needsParens) {
			result += ')';
		}
		return result;
	};

	var formatExpression = function(expression, options) {

		options = extend({
			'precedence': 0,
			'preserveIdentifiers': false
		}, options);

		var result = '';
		var currentPrecedence;
		var associativity;
		var operator;

		var expressionType = expression.type;

		if (expressionType == 'Identifier') {

			result = expression.isLocal && !options.preserveIdentifiers
				? generateIdentifier(expression.name)
				: expression.name;

		} else if (
			expressionType == 'StringLiteral' ||
			expressionType == 'NumericLiteral' ||
			expressionType == 'BooleanLiteral' ||
			expressionType == 'NilLiteral' ||
			expressionType == 'VarargLiteral'
		) {

			result = expression.raw;

		} else if (
			expressionType == 'LogicalExpression' ||
			expressionType == 'BinaryExpression'
		) {

			// If an expression with precedence x
			// contains an expression with precedence < x,
			// the inner expression must be wrapped in parens.
			operator = expression.operator;
			currentPrecedence = PRECEDENCE[operator];
			associativity = 'left';

			result = formatExpression(expression.left, {
				'precedence': currentPrecedence,
				'direction': 'left',
				'parent': operator
			});
			result = joinStatements(result, operator);
			result = joinStatements(result, formatExpression(expression.right, {
				'precedence': currentPrecedence,
				'direction': 'right',
				'parent': operator
			}));

			if (operator == '^' || operator == '..') {
				associativity = "right";
			}

			if (
				currentPrecedence < options.precedence ||
				(
					currentPrecedence == options.precedence &&
					associativity != options.direction &&
					options.parent != '+' &&
					!(options.parent == '*' && (operator == '/' || operator == '*'))
				)
			) {
				// The most simple case here is that of
				// protecting the parentheses on the RHS of
				// `1 - (2 - 3)` but deleting them from `(1 - 2) - 3`.
				// This is generally the right thing to do. The
				// semantics of `+` are special however: `1 + (2 - 3)`
				// == `1 + 2 - 3`. `-` and `+` are the only two operators
				// who share their precedence level. `*` also can
				// commute in such a way with `/`, but not with `%`
				// (all three share a precedence). So we test for
				// all of these conditions and avoid emitting
				// parentheses in the cases where we don’t have to.
				result = '(' + result + ')';
			}

		} else if (expressionType == 'UnaryExpression') {

			operator = expression.operator;
			currentPrecedence = PRECEDENCE['unary' + operator];

			result = joinStatements(
				operator,
				formatExpression(expression.argument, {
					'precedence': currentPrecedence
				})
			);

			if (
				currentPrecedence < options.precedence &&
				// In principle, we should parenthesize the RHS of an
				// expression like `3^-2`, because `^` has higher precedence
				// than unary `-` according to the manual. But that is
				// misleading on the RHS of `^`, since the parser will
				// always try to find a unary operator regardless of
				// precedence.
				!(
					(options.parent == '^') &&
					options.direction == 'right'
				)
			) {
				result = '(' + result + ')';
			}

		} else if (expressionType == 'CallExpression') {

			result = formatBase(expression.base) + '(';

			each(expression.arguments, function(argument, needsComma) {
				result += formatExpression(argument);
				if (needsComma) {
					result += ',';
				}
			});
			result += ')';

		} else if (expressionType == 'TableCallExpression') {

			result = formatExpression(expression.base) +
				formatExpression(expression.arguments);

		} else if (expressionType == 'StringCallExpression') {

			result = formatExpression(expression.base) +
				formatExpression(expression.argument);

		} else if (expressionType == 'IndexExpression') {

			result = formatBase(expression.base) + '[' +
				formatExpression(expression.index) + ']';

		} else if (expressionType == 'MemberExpression') {

			result = formatBase(expression.base) + expression.indexer +
				formatExpression(expression.identifier, {
					'preserveIdentifiers': true
				});

		} else if (expressionType == 'FunctionDeclaration') {

			result = 'function(';
			if (expression.parameters.length) {
				each(expression.parameters, function(parameter, needsComma) {
					// `Identifier`s have a `name`, `VarargLiteral`s have a `value`
					result += parameter.name
						? generateIdentifier(parameter.name)
						: parameter.value;
					if (needsComma) {
						result += ',';
					}
				});
			}
			result += ')';
			result = joinStatements(result, formatStatementList(expression.body));
			result = joinStatements(result, 'end');

		} else if (expressionType == 'TableConstructorExpression') {

			result = '{';

			each(expression.fields, function(field, needsComma) {
				if (field.type == 'TableKey') {
					result += '[' + formatExpression(field.key) + ']=' +
						formatExpression(field.value);
				} else if (field.type == 'TableValue') {
					result += formatExpression(field.value);
				} else { // at this point, `field.type == 'TableKeyString'`
					result += formatExpression(field.key, {
						// TODO: keep track of nested scopes (#18)
						'preserveIdentifiers': true
					}) + '=' + formatExpression(field.value);
				}
				if (needsComma) {
					result += ',';
				}
			});

			result += '}';

		} else {

			throw TypeError('Unknown expression type: `' + expressionType + '`');

		}

		return result;
	};

	var formatStatementList = function(body) {
		var result = '';
		each(body, function(statement) {
			result = joinStatements(result, formatStatement(statement), ';');
		});
		return result;
	};

	var formatStatement = function(statement) {
		var result = '';
		var statementType = statement.type;

		if (statementType == 'AssignmentStatement') {

			// left-hand side
			each(statement.variables, function(variable, needsComma) {
				result += formatExpression(variable);
				if (needsComma) {
					result += ',';
				}
			});

			// right-hand side
			result += '=';
			each(statement.init, function(init, needsComma) {
				result += formatExpression(init);
				if (needsComma) {
					result += ',';
				}
			});

		} else if (statementType == 'LocalStatement') {

			result = 'local ';

			// left-hand side
			each(statement.variables, function(variable, needsComma) {
				// Variables in a `LocalStatement` are always local, duh
				result += generateIdentifier(variable.name);
				if (needsComma) {
					result += ',';
				}
			});

			// right-hand side
			if (statement.init.length) {
				result += '=';
				each(statement.init, function(init, needsComma) {
					result += formatExpression(init);
					if (needsComma) {
						result += ',';
					}
				});
			}

		} else if (statementType == 'CallStatement') {

			result = formatExpression(statement.expression);

		} else if (statementType == 'IfStatement') {

			result = joinStatements(
				'if',
				formatExpression(statement.clauses[0].condition)
			);
			result = joinStatements(result, 'then');
			result = joinStatements(
				result,
				formatStatementList(statement.clauses[0].body)
			);
			each(statement.clauses.slice(1), function(clause) {
				if (clause.condition) {
					result = joinStatements(result, 'elseif');
					result = joinStatements(result, formatExpression(clause.condition));
					result = joinStatements(result, 'then');
				} else {
					result = joinStatements(result, 'else');
				}
				result = joinStatements(result, formatStatementList(clause.body));
			});
			result = joinStatements(result, 'end');

		} else if (statementType == 'WhileStatement') {

			result = joinStatements('while', formatExpression(statement.condition));
			result = joinStatements(result, 'do');
			result = joinStatements(result, formatStatementList(statement.body));
			result = joinStatements(result, 'end');

		} else if (statementType == 'DoStatement') {

			result = joinStatements('do', formatStatementList(statement.body));
			result = joinStatements(result, 'end');

		} else if (statementType == 'ReturnStatement') {

			result = 'return';

			each(statement.arguments, function(argument, needsComma) {
				result = joinStatements(result, formatExpression(argument));
				if (needsComma) {
					result += ',';
				}
			});

		} else if (statementType == 'BreakStatement') {

			result = 'break';

		} else if (statementType == 'RepeatStatement') {

			result = joinStatements('repeat', formatStatementList(statement.body));
			result = joinStatements(result, 'until');
			result = joinStatements(result, formatExpression(statement.condition))

		} else if (statementType == 'FunctionDeclaration') {

			result = (statement.isLocal ? 'local ' : '') + 'function ';
			result += formatExpression(statement.identifier);
			result += '(';

			if (statement.parameters.length) {
				each(statement.parameters, function(parameter, needsComma) {
					// `Identifier`s have a `name`, `VarargLiteral`s have a `value`
					result += parameter.name
						? generateIdentifier(parameter.name)
						: parameter.value;
					if (needsComma) {
						result += ',';
					}
				});
			}

			result += ')';
			result = joinStatements(result, formatStatementList(statement.body));
			result = joinStatements(result, 'end');

		} else if (statementType == 'ForGenericStatement') {
			// see also `ForNumericStatement`

			result = 'for ';

			each(statement.variables, function(variable, needsComma) {
				// The variables in a `ForGenericStatement` are always local
				result += generateIdentifier(variable.name);
				if (needsComma) {
					result += ',';
				}
			});

			result += ' in';

			each(statement.iterators, function(iterator, needsComma) {
				result = joinStatements(result, formatExpression(iterator));
				if (needsComma) {
					result += ',';
				}
			});

			result = joinStatements(result, 'do');
			result = joinStatements(result, formatStatementList(statement.body));
			result = joinStatements(result, 'end');

		} else if (statementType == 'ForNumericStatement') {

			// The variables in a `ForNumericStatement` are always local
			result = 'for ' + generateIdentifier(statement.variable.name) + '=';
			result += formatExpression(statement.start) + ',' +
				formatExpression(statement.end);

			if (statement.step) {
				result += ',' + formatExpression(statement.step);
			}

			result = joinStatements(result, 'do');
			result = joinStatements(result, formatStatementList(statement.body));
			result = joinStatements(result, 'end');

		} else if (statementType == 'LabelStatement') {

			// The identifier names in a `LabelStatement` can safely be renamed
			result = '::' + generateIdentifier(statement.label.name) + '::';

		} else if (statementType == 'GotoStatement') {

			// The identifier names in a `GotoStatement` can safely be renamed
			result = 'goto ' + generateIdentifier(statement.label.name);

		} else {

			throw TypeError('Unknown statement type: `' + statementType + '`');

		}

		return result;
	};

	var minify = function(argument) {
		// `argument` can be a Lua code snippet (string)
		// or a luaparse-compatible AST (object)
		var ast = typeof argument == 'string'
			? parse(argument)
			: argument;

		// (Re)set temporary identifier values
		identifierMap = {};
		identifiersInUse = [];
		// This is a shortcut to help generate the first identifier (`a`) faster
		currentIdentifier = '9';

		// Make sure global variable names aren't renamed
		if (ast.globals) {
			each(ast.globals, function(object) {
				var name = object.name;
				identifierMap[name] = name;
				identifiersInUse.push(name);
			});
		} else {
			throw Error('Missing required AST property: `globals`');
		}

		return formatStatementList(ast.body);
	};

	/*--------------------------------------------------------------------------*/

	var luamin = {
		'version': '1.0.4',
		'minify': minify
	};

	// Some AMD build optimizers, like r.js, check for specific condition patterns
	// like the following:
	if (
		typeof define == 'function' &&
		typeof define.amd == 'object' &&
		define.amd
	) {
		define(function() {
			return luamin;
		});
	}	else if (freeExports && !freeExports.nodeType) {
		if (freeModule) { // in Node.js or RingoJS v0.8.0+
			freeModule.exports = luamin;
		} else { // in Narwhal or RingoJS v0.7.0-
			extend(freeExports, luamin);
		}
	} else { // in Rhino or a web browser
		root.luamin = luamin;
	}

}(this));


/***/ }),

/***/ 1021:
/***/ (function(module, exports, __nccwpck_require__) {

/* module decorator */ module = __nccwpck_require__.nmd(module);
/* global exports:true, module:true, require:true, define:true, global:true */

(function (root, name, factory) {
  /* jshint eqeqeq:false */
  'use strict';

  // Used to determine if values are of the language type `Object`
  var objectTypes = {
        'function': true
      , 'object': true
    }
    // Detect free variable `exports`
    , freeExports = objectTypes[typeof exports] && exports && !exports.nodeType && exports
    // Detect free variable `module`
    , freeModule = objectTypes["object"] && module && !module.nodeType && module
    // Detect free variable `global`, from Node.js or Browserified code, and
    // use it as `window`
    , freeGlobal = freeExports && freeModule && typeof global == 'object' && global
    // Detect the popular CommonJS extension `module.exports`
    , moduleExports = freeModule && freeModule.exports === freeExports && freeExports;

  if (freeGlobal && (freeGlobal.global === freeGlobal || freeGlobal.window === freeGlobal || freeGlobal.self === freeGlobal)) {
    root = freeGlobal;
  }

  // Some AMD build optimizers, like r.js, check for specific condition
  // patterns like the following:
  if (typeof define == 'function' && typeof define.amd == 'object' && define.amd) {
    // defined as an anonymous module.
    define(['exports'], factory);
    // In case the source has been processed and wrapped in a define module use
    // the supplied `exports` object.
    if (freeExports && moduleExports) factory(freeModule.exports);
  }
  // check for `exports` after `define` in case a build optimizer adds an
  // `exports` object
  else if (freeExports && freeModule) {
    // in Node.js or RingoJS v0.8.0+
    if (moduleExports) factory(freeModule.exports);
    // in Narwhal or RingoJS v0.7.0-
    else factory(freeExports);
  }
  // in a browser or Rhino
  else {
    factory((root[name] = {}));
  }
}(this, 'luaparse', function (exports) {
  'use strict';

  exports.version = '0.2.1';

  var input, options, length;

  // Options can be set either globally on the parser object through
  // defaultOptions, or during the parse call.
  var defaultOptions = exports.defaultOptions = {
    // Explicitly tell the parser when the input ends.
      wait: false
    // Store comments as an array in the chunk object.
    , comments: true
    // Track identifier scopes by adding an isLocal attribute to each
    // identifier-node.
    , scope: false
    // Store location information on each syntax node as
    // `loc: { start: { line, column }, end: { line, column } }`.
    , locations: false
    // Store the start and end character locations on each syntax node as
    // `range: [start, end]`.
    , ranges: false
    // A callback which will be invoked when a syntax node has been completed.
    // The node which has been created will be passed as the only parameter.
    , onCreateNode: null
    // A callback which will be invoked when a new scope is created.
    , onCreateScope: null
    // A callback which will be invoked when the current scope is destroyed.
    , onDestroyScope: null
  };

  // The available tokens expressed as enum flags so they can be checked with
  // bitwise operations.

  var EOF = 1, StringLiteral = 2, Keyword = 4, Identifier = 8
    , NumericLiteral = 16, Punctuator = 32, BooleanLiteral = 64
    , NilLiteral = 128, VarargLiteral = 256;

  exports.tokenTypes = { EOF: EOF, StringLiteral: StringLiteral
    , Keyword: Keyword, Identifier: Identifier, NumericLiteral: NumericLiteral
    , Punctuator: Punctuator, BooleanLiteral: BooleanLiteral
    , NilLiteral: NilLiteral, VarargLiteral: VarargLiteral
  };

  // As this parser is a bit different from luas own, the error messages
  // will be different in some situations.

  var errors = exports.errors = {
      unexpected: 'unexpected %1 \'%2\' near \'%3\''
    , expected: '\'%1\' expected near \'%2\''
    , expectedToken: '%1 expected near \'%2\''
    , unfinishedString: 'unfinished string near \'%1\''
    , malformedNumber: 'malformed number near \'%1\''
    , invalidVar: 'invalid left-hand side of assignment near \'%1\''
  };

  // ### Abstract Syntax Tree
  //
  // The default AST structure is inspired by the Mozilla Parser API but can
  // easily be customized by overriding these functions.

  var ast = exports.ast = {
      labelStatement: function(label) {
      return {
          type: 'LabelStatement'
        , label: label
      };
    }

    , breakStatement: function() {
      return {
          type: 'BreakStatement'
      };
    }

    , gotoStatement: function(label) {
      return {
          type: 'GotoStatement'
        , label: label
      };
    }

    , returnStatement: function(args) {
      return {
          type: 'ReturnStatement'
        , 'arguments': args
      };
    }

    , ifStatement: function(clauses) {
      return {
          type: 'IfStatement'
        , clauses: clauses
      };
    }
    , ifClause: function(condition, body) {
      return {
          type: 'IfClause'
        , condition: condition
        , body: body
      };
    }
    , elseifClause: function(condition, body) {
      return {
          type: 'ElseifClause'
        , condition: condition
        , body: body
      };
    }
    , elseClause: function(body) {
      return {
          type: 'ElseClause'
        , body: body
      };
    }

    , whileStatement: function(condition, body) {
      return {
          type: 'WhileStatement'
        , condition: condition
        , body: body
      };
    }

    , doStatement: function(body) {
      return {
          type: 'DoStatement'
        , body: body
      };
    }

    , repeatStatement: function(condition, body) {
      return {
          type: 'RepeatStatement'
        , condition: condition
        , body: body
      };
    }

    , localStatement: function(variables, init) {
      return {
          type: 'LocalStatement'
        , variables: variables
        , init: init
      };
    }

    , assignmentStatement: function(variables, init) {
      return {
          type: 'AssignmentStatement'
        , variables: variables
        , init: init
      };
    }

    , callStatement: function(expression) {
      return {
          type: 'CallStatement'
        , expression: expression
      };
    }

    , functionStatement: function(identifier, parameters, isLocal, body) {
      return {
          type: 'FunctionDeclaration'
        , identifier: identifier
        , isLocal: isLocal
        , parameters: parameters
        , body: body
      };
    }

    , forNumericStatement: function(variable, start, end, step, body) {
      return {
          type: 'ForNumericStatement'
        , variable: variable
        , start: start
        , end: end
        , step: step
        , body: body
      };
    }

    , forGenericStatement: function(variables, iterators, body) {
      return {
          type: 'ForGenericStatement'
        , variables: variables
        , iterators: iterators
        , body: body
      };
    }

    , chunk: function(body) {
      return {
          type: 'Chunk'
        , body: body
      };
    }

    , identifier: function(name) {
      return {
          type: 'Identifier'
        , name: name
      };
    }

    , literal: function(type, value, raw) {
      type = (type === StringLiteral) ? 'StringLiteral'
        : (type === NumericLiteral) ? 'NumericLiteral'
        : (type === BooleanLiteral) ? 'BooleanLiteral'
        : (type === NilLiteral) ? 'NilLiteral'
        : 'VarargLiteral';

      return {
          type: type
        , value: value
        , raw: raw
      };
    }

    , tableKey: function(key, value) {
      return {
          type: 'TableKey'
        , key: key
        , value: value
      };
    }
    , tableKeyString: function(key, value) {
      return {
          type: 'TableKeyString'
        , key: key
        , value: value
      };
    }
    , tableValue: function(value) {
      return {
          type: 'TableValue'
        , value: value
      };
    }


    , tableConstructorExpression: function(fields) {
      return {
          type: 'TableConstructorExpression'
        , fields: fields
      };
    }
    , binaryExpression: function(operator, left, right) {
      var type = ('and' === operator || 'or' === operator) ?
        'LogicalExpression' :
        'BinaryExpression';

      return {
          type: type
        , operator: operator
        , left: left
        , right: right
      };
    }
    , unaryExpression: function(operator, argument) {
      return {
          type: 'UnaryExpression'
        , operator: operator
        , argument: argument
      };
    }
    , memberExpression: function(base, indexer, identifier) {
      return {
          type: 'MemberExpression'
        , indexer: indexer
        , identifier: identifier
        , base: base
      };
    }

    , indexExpression: function(base, index) {
      return {
          type: 'IndexExpression'
        , base: base
        , index: index
      };
    }

    , callExpression: function(base, args) {
      return {
          type: 'CallExpression'
        , base: base
        , 'arguments': args
      };
    }

    , tableCallExpression: function(base, args) {
      return {
          type: 'TableCallExpression'
        , base: base
        , 'arguments': args
      };
    }

    , stringCallExpression: function(base, argument) {
      return {
          type: 'StringCallExpression'
        , base: base
        , argument: argument
      };
    }

    , comment: function(value, raw) {
      return {
          type: 'Comment'
        , value: value
        , raw: raw
      };
    }
  };

  // Wrap up the node object.

  function finishNode(node) {
    // Pop a `Marker` off the location-array and attach its location data.
    if (trackLocations) {
      var location = locations.pop();
      location.complete();
      if (options.locations) node.loc = location.loc;
      if (options.ranges) node.range = location.range;
    }
    if (options.onCreateNode) options.onCreateNode(node);
    return node;
  }


  // Helpers
  // -------

  var slice = Array.prototype.slice
    , toString = Object.prototype.toString
    , indexOf = function indexOf(array, element) {
      for (var i = 0, length = array.length; i < length; i++) {
        if (array[i] === element) return i;
      }
      return -1;
    };

  // Iterate through an array of objects and return the index of an object
  // with a matching property.

  function indexOfObject(array, property, element) {
    for (var i = 0, length = array.length; i < length; i++) {
      if (array[i][property] === element) return i;
    }
    return -1;
  }

  // A sprintf implementation using %index (beginning at 1) to input
  // arguments in the format string.
  //
  // Example:
  //
  //     // Unexpected function in token
  //     sprintf('Unexpected %2 in %1.', 'token', 'function');

  function sprintf(format) {
    var args = slice.call(arguments, 1);
    format = format.replace(/%(\d)/g, function (match, index) {
      return '' + args[index - 1] || '';
    });
    return format;
  }

  // Returns a new object with the properties from all objectes passed as
  // arguments. Last argument takes precedence.
  //
  // Example:
  //
  //     this.options = extend(options, { output: false });

  function extend() {
    var args = slice.call(arguments)
      , dest = {}
      , src, prop;

    for (var i = 0, length = args.length; i < length; i++) {
      src = args[i];
      for (prop in src) if (src.hasOwnProperty(prop)) {
        dest[prop] = src[prop];
      }
    }
    return dest;
  }

  // ### Error functions

  // #### Raise an exception.
  //
  // Raise an exception by passing a token, a string format and its paramters.
  //
  // The passed tokens location will automatically be added to the error
  // message if it exists, if not it will default to the lexers current
  // position.
  //
  // Example:
  //
  //     // [1:0] expected [ near (
  //     raise(token, "expected %1 near %2", '[', token.value);

  function raise(token) {
    var message = sprintf.apply(null, slice.call(arguments, 1))
      , error, col;

    if ('undefined' !== typeof token.line) {
      col = token.range[0] - token.lineStart;
      error = new SyntaxError(sprintf('[%1:%2] %3', token.line, col, message));
      error.line = token.line;
      error.index = token.range[0];
      error.column = col;
    } else {
      col = index - lineStart + 1;
      error = new SyntaxError(sprintf('[%1:%2] %3', line, col, message));
      error.index = index;
      error.line = line;
      error.column = col;
    }
    throw error;
  }

  // #### Raise an unexpected token error.
  //
  // Example:
  //
  //     // expected <name> near '0'
  //     raiseUnexpectedToken('<name>', token);

  function raiseUnexpectedToken(type, token) {
    raise(token, errors.expectedToken, type, token.value);
  }

  // #### Raise a general unexpected error
  //
  // Usage should pass either a token object or a symbol string which was
  // expected. We can also specify a nearby token such as <eof>, this will
  // default to the currently active token.
  //
  // Example:
  //
  //     // Unexpected symbol 'end' near '<eof>'
  //     unexpected(token);
  //
  // If there's no token in the buffer it means we have reached <eof>.

  function unexpected(found, near) {
    if ('undefined' === typeof near) near = lookahead.value;
    if ('undefined' !== typeof found.type) {
      var type;
      switch (found.type) {
        case StringLiteral:   type = 'string';      break;
        case Keyword:         type = 'keyword';     break;
        case Identifier:      type = 'identifier';  break;
        case NumericLiteral:  type = 'number';      break;
        case Punctuator:      type = 'symbol';      break;
        case BooleanLiteral:  type = 'boolean';     break;
        case NilLiteral:
          return raise(found, errors.unexpected, 'symbol', 'nil', near);
      }
      return raise(found, errors.unexpected, type, found.value, near);
    }
    return raise(found, errors.unexpected, 'symbol', found, near);
  }

  // Lexer
  // -----
  //
  // The lexer, or the tokenizer reads the input string character by character
  // and derives a token left-right. To be as efficient as possible the lexer
  // prioritizes the common cases such as identifiers. It also works with
  // character codes instead of characters as string comparisons was the
  // biggest bottleneck of the parser.
  //
  // If `options.comments` is enabled, all comments encountered will be stored
  // in an array which later will be appended to the chunk object. If disabled,
  // they will simply be disregarded.
  //
  // When the lexer has derived a valid token, it will be returned as an object
  // containing its value and as well as its position in the input string (this
  // is always enabled to provide proper debug messages).
  //
  // `lex()` starts lexing and returns the following token in the stream.

  var index
    , token
    , previousToken
    , lookahead
    , comments
    , tokenStart
    , line
    , lineStart;

  exports.lex = lex;

  function lex() {
    skipWhiteSpace();

    // Skip comments beginning with --
    while (45 === input.charCodeAt(index) &&
           45 === input.charCodeAt(index + 1)) {
      scanComment();
      skipWhiteSpace();
    }
    if (index >= length) return {
        type : EOF
      , value: '<eof>'
      , line: line
      , lineStart: lineStart
      , range: [index, index]
    };

    var charCode = input.charCodeAt(index)
      , next = input.charCodeAt(index + 1);

    // Memorize the range index where the token begins.
    tokenStart = index;
    if (isIdentifierStart(charCode)) return scanIdentifierOrKeyword();

    switch (charCode) {
      case 39: case 34: // '"
        return scanStringLiteral();

      // 0-9
      case 48: case 49: case 50: case 51: case 52: case 53:
      case 54: case 55: case 56: case 57:
        return scanNumericLiteral();

      case 46: // .
        // If the dot is followed by a digit it's a float.
        if (isDecDigit(next)) return scanNumericLiteral();
        if (46 === next) {
          if (46 === input.charCodeAt(index + 2)) return scanVarargLiteral();
          return scanPunctuator('..');
        }
        return scanPunctuator('.');

      case 61: // =
        if (61 === next) return scanPunctuator('==');
        return scanPunctuator('=');

      case 62: // >
        if (61 === next) return scanPunctuator('>=');
        if (62 === next) return scanPunctuator('>>');
        return scanPunctuator('>');

      case 60: // <
        if (60 === next) return scanPunctuator('<<');
        if (61 === next) return scanPunctuator('<=');
        return scanPunctuator('<');

      case 126: // ~
        if (61 === next) return scanPunctuator('~=');
        return scanPunctuator('~');

      case 58: // :
        if (58 === next) return scanPunctuator('::');
        return scanPunctuator(':');

      case 91: // [
        // Check for a multiline string, they begin with [= or [[
        if (91 === next || 61 === next) return scanLongStringLiteral();
        return scanPunctuator('[');

      case 47: // /
        // Check for integer division op (//)
        if (47 === next) return scanPunctuator('//');
        return scanPunctuator('/');

      // * ^ % , { } ] ( ) ; & # - + |
      case 42: case 94: case 37: case 44: case 123: case 124: case 125:
      case 93: case 40: case 41: case 59: case 38: case 35: case 45: case 43:
        return scanPunctuator(input.charAt(index));
    }

    return unexpected(input.charAt(index));
  }

  // Whitespace has no semantic meaning in lua so simply skip ahead while
  // tracking the encounted newlines. Any kind of eol sequence is counted as a
  // single line.

  function consumeEOL() {
    var charCode = input.charCodeAt(index)
      , peekCharCode = input.charCodeAt(index + 1);

    if (isLineTerminator(charCode)) {
      // Count \n\r and \r\n as one newline.
      if (10 === charCode && 13 === peekCharCode) index++;
      if (13 === charCode && 10 === peekCharCode) index++;
      line++;
      lineStart = ++index;

      return true;
    }
    return false;
  }

  function skipWhiteSpace() {
    while (index < length) {
      var charCode = input.charCodeAt(index);
      if (isWhiteSpace(charCode)) {
        index++;
      } else if (!consumeEOL()) {
        break;
      }
    }
  }

  // Identifiers, keywords, booleans and nil all look the same syntax wise. We
  // simply go through them one by one and defaulting to an identifier if no
  // previous case matched.

  function scanIdentifierOrKeyword() {
    var value, type;

    // Slicing the input string is prefered before string concatenation in a
    // loop for performance reasons.
    while (isIdentifierPart(input.charCodeAt(++index)));
    value = input.slice(tokenStart, index);

    // Decide on the token type and possibly cast the value.
    if (isKeyword(value)) {
      type = Keyword;
    } else if ('true' === value || 'false' === value) {
      type = BooleanLiteral;
      value = ('true' === value);
    } else if ('nil' === value) {
      type = NilLiteral;
      value = null;
    } else {
      type = Identifier;
    }

    return {
        type: type
      , value: value
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Once a punctuator reaches this function it should already have been
  // validated so we simply return it as a token.

  function scanPunctuator(value) {
    index += value.length;
    return {
        type: Punctuator
      , value: value
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // A vararg literal consists of three dots.

  function scanVarargLiteral() {
    index += 3;
    return {
        type: VarargLiteral
      , value: '...'
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Find the string literal by matching the delimiter marks used.

  function scanStringLiteral() {
    var delimiter = input.charCodeAt(index++)
      , stringStart = index
      , string = ''
      , charCode;

    while (index < length) {
      charCode = input.charCodeAt(index++);
      if (delimiter === charCode) break;
      if (92 === charCode) { // \
        string += input.slice(stringStart, index - 1) + readEscapeSequence();
        stringStart = index;
      }
      // EOF or `\n` terminates a string literal. If we haven't found the
      // ending delimiter by now, raise an exception.
      else if (index >= length || isLineTerminator(charCode)) {
        string += input.slice(stringStart, index - 1);
        raise({}, errors.unfinishedString, string + String.fromCharCode(charCode));
      }
    }
    string += input.slice(stringStart, index - 1);

    return {
        type: StringLiteral
      , value: string
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Expect a multiline string literal and return it as a regular string
  // literal, if it doesn't validate into a valid multiline string, throw an
  // exception.

  function scanLongStringLiteral() {
    var string = readLongString();
    // Fail if it's not a multiline literal.
    if (false === string) raise(token, errors.expected, '[', token.value);

    return {
        type: StringLiteral
      , value: string
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Numeric literals will be returned as floating-point numbers instead of
  // strings. The raw value should be retrieved from slicing the input string
  // later on in the process.
  //
  // If a hexadecimal number is encountered, it will be converted.

  function scanNumericLiteral() {
    var character = input.charAt(index)
      , next = input.charAt(index + 1);

    var value = ('0' === character && 'xX'.indexOf(next || null) >= 0) ?
      readHexLiteral() : readDecLiteral();

    return {
        type: NumericLiteral
      , value: value
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Lua hexadecimals have an optional fraction part and an optional binary
  // exoponent part. These are not included in JavaScript so we will compute
  // all three parts separately and then sum them up at the end of the function
  // with the following algorithm.
  //
  //     Digit := toDec(digit)
  //     Fraction := toDec(fraction) / 16 ^ fractionCount
  //     BinaryExp := 2 ^ binaryExp
  //     Number := ( Digit + Fraction ) * BinaryExp

  function readHexLiteral() {
    var fraction = 0 // defaults to 0 as it gets summed
      , binaryExponent = 1 // defaults to 1 as it gets multiplied
      , binarySign = 1 // positive
      , digit, fractionStart, exponentStart, digitStart;

    digitStart = index += 2; // Skip 0x part

    // A minimum of one hex digit is required.
    if (!isHexDigit(input.charCodeAt(index)))
      raise({}, errors.malformedNumber, input.slice(tokenStart, index));

    while (isHexDigit(input.charCodeAt(index))) index++;
    // Convert the hexadecimal digit to base 10.
    digit = parseInt(input.slice(digitStart, index), 16);

    // Fraction part i optional.
    if ('.' === input.charAt(index)) {
      fractionStart = ++index;

      while (isHexDigit(input.charCodeAt(index))) index++;
      fraction = input.slice(fractionStart, index);

      // Empty fraction parts should default to 0, others should be converted
      // 0.x form so we can use summation at the end.
      fraction = (fractionStart === index) ? 0
        : parseInt(fraction, 16) / Math.pow(16, index - fractionStart);
    }

    // Binary exponents are optional
    if ('pP'.indexOf(input.charAt(index) || null) >= 0) {
      index++;

      // Sign part is optional and defaults to 1 (positive).
      if ('+-'.indexOf(input.charAt(index) || null) >= 0)
        binarySign = ('+' === input.charAt(index++)) ? 1 : -1;

      exponentStart = index;

      // The binary exponent sign requires a decimal digit.
      if (!isDecDigit(input.charCodeAt(index)))
        raise({}, errors.malformedNumber, input.slice(tokenStart, index));

      while (isDecDigit(input.charCodeAt(index))) index++;
      binaryExponent = input.slice(exponentStart, index);

      // Calculate the binary exponent of the number.
      binaryExponent = Math.pow(2, binaryExponent * binarySign);
    }

    return (digit + fraction) * binaryExponent;
  }

  // Decimal numbers are exactly the same in Lua and in JavaScript, because of
  // this we check where the token ends and then parse it with native
  // functions.

  function readDecLiteral() {
    while (isDecDigit(input.charCodeAt(index))) index++;
    // Fraction part is optional
    if ('.' === input.charAt(index)) {
      index++;
      // Fraction part defaults to 0
      while (isDecDigit(input.charCodeAt(index))) index++;
    }
    // Exponent part is optional.
    if ('eE'.indexOf(input.charAt(index) || null) >= 0) {
      index++;
      // Sign part is optional.
      if ('+-'.indexOf(input.charAt(index) || null) >= 0) index++;
      // An exponent is required to contain at least one decimal digit.
      if (!isDecDigit(input.charCodeAt(index)))
        raise({}, errors.malformedNumber, input.slice(tokenStart, index));

      while (isDecDigit(input.charCodeAt(index))) index++;
    }

    return parseFloat(input.slice(tokenStart, index));
  }


  // Translate escape sequences to the actual characters.

  function readEscapeSequence() {
    var sequenceStart = index;
    switch (input.charAt(index)) {
      // Lua allow the following escape sequences.
      // We don't escape the bell sequence.
      case 'n': index++; return '\n';
      case 'r': index++; return '\r';
      case 't': index++; return '\t';
      case 'v': index++; return '\x0B';
      case 'b': index++; return '\b';
      case 'f': index++; return '\f';
      // Skips the following span of white-space.
      case 'z': index++; skipWhiteSpace(); return '';
      // Byte representation should for now be returned as is.
      case 'x':
        // \xXX, where XX is a sequence of exactly two hexadecimal digits
        if (isHexDigit(input.charCodeAt(index + 1)) &&
            isHexDigit(input.charCodeAt(index + 2))) {
          index += 3;
          // Return it as is, without translating the byte.
          return '\\' + input.slice(sequenceStart, index);
        }
        return '\\' + input.charAt(index++);
      default:
        // \ddd, where ddd is a sequence of up to three decimal digits.
        if (isDecDigit(input.charCodeAt(index))) {
          while (isDecDigit(input.charCodeAt(++index)));
          return '\\' + input.slice(sequenceStart, index);
        }
        // Simply return the \ as is, it's not escaping any sequence.
        return input.charAt(index++);
    }
  }

  // Comments begin with -- after which it will be decided if they are
  // multiline comments or not.
  //
  // The multiline functionality works the exact same way as with string
  // literals so we reuse the functionality.

  function scanComment() {
    tokenStart = index;
    index += 2; // --

    var character = input.charAt(index)
      , content = ''
      , isLong = false
      , commentStart = index
      , lineStartComment = lineStart
      , lineComment = line;

    if ('[' === character) {
      content = readLongString();
      // This wasn't a multiline comment after all.
      if (false === content) content = character;
      else isLong = true;
    }
    // Scan until next line as long as it's not a multiline comment.
    if (!isLong) {
      while (index < length) {
        if (isLineTerminator(input.charCodeAt(index))) break;
        index++;
      }
      if (options.comments) content = input.slice(commentStart, index);
    }

    if (options.comments) {
      var node = ast.comment(content, input.slice(tokenStart, index));

      // `Marker`s depend on tokens available in the parser and as comments are
      // intercepted in the lexer all location data is set manually.
      if (options.locations) {
        node.loc = {
            start: { line: lineComment, column: tokenStart - lineStartComment }
          , end: { line: line, column: index - lineStart }
        };
      }
      if (options.ranges) {
        node.range = [tokenStart, index];
      }
      if (options.onCreateNode) options.onCreateNode(node);
      comments.push(node);
    }
  }

  // Read a multiline string by calculating the depth of `=` characters and
  // then appending until an equal depth is found.

  function readLongString() {
    var level = 0
      , content = ''
      , terminator = false
      , character, stringStart;

    index++; // [

    // Calculate the depth of the comment.
    while ('=' === input.charAt(index + level)) level++;
    // Exit, this is not a long string afterall.
    if ('[' !== input.charAt(index + level)) return false;

    index += level + 1;

    // If the first character is a newline, ignore it and begin on next line.
    if (isLineTerminator(input.charCodeAt(index))) consumeEOL();

    stringStart = index;
    while (index < length) {
      // To keep track of line numbers run the `consumeEOL()` which increments
      // its counter.
      if (isLineTerminator(input.charCodeAt(index))) consumeEOL();

      character = input.charAt(index++);

      // Once the delimiter is found, iterate through the depth count and see
      // if it matches.
      if (']' === character) {
        terminator = true;
        for (var i = 0; i < level; i++) {
          if ('=' !== input.charAt(index + i)) terminator = false;
        }
        if (']' !== input.charAt(index + level)) terminator = false;
      }

      // We reached the end of the multiline string. Get out now.
      if (terminator) break;
    }
    content += input.slice(stringStart, index - 1);
    index += level + 1;

    return content;
  }

  // ## Lex functions and helpers.

  // Read the next token.
  //
  // This is actually done by setting the current token to the lookahead and
  // reading in the new lookahead token.

  function next() {
    previousToken = token;
    token = lookahead;
    lookahead = lex();
  }

  // Consume a token if its value matches. Once consumed or not, return the
  // success of the operation.

  function consume(value) {
    if (value === token.value) {
      next();
      return true;
    }
    return false;
  }

  // Expect the next token value to match. If not, throw an exception.

  function expect(value) {
    if (value === token.value) next();
    else raise(token, errors.expected, value, token.value);
  }

  // ### Validation functions

  function isWhiteSpace(charCode) {
    return 9 === charCode || 32 === charCode || 0xB === charCode || 0xC === charCode;
  }

  function isLineTerminator(charCode) {
    return 10 === charCode || 13 === charCode;
  }

  function isDecDigit(charCode) {
    return charCode >= 48 && charCode <= 57;
  }

  function isHexDigit(charCode) {
    return (charCode >= 48 && charCode <= 57) || (charCode >= 97 && charCode <= 102) || (charCode >= 65 && charCode <= 70);
  }

  // From [Lua 5.2](http://www.lua.org/manual/5.2/manual.html#8.1) onwards
  // identifiers cannot use locale-dependet letters.

  function isIdentifierStart(charCode) {
    return (charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122) || 95 === charCode;
  }

  function isIdentifierPart(charCode) {
    return (charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122) || 95 === charCode || (charCode >= 48 && charCode <= 57);
  }

  // [3.1 Lexical Conventions](http://www.lua.org/manual/5.2/manual.html#3.1)
  //
  // `true`, `false` and `nil` will not be considered keywords, but literals.

  function isKeyword(id) {
    switch (id.length) {
      case 2:
        return 'do' === id || 'if' === id || 'in' === id || 'or' === id;
      case 3:
        return 'and' === id || 'end' === id || 'for' === id || 'not' === id;
      case 4:
        return 'else' === id || 'goto' === id || 'then' === id;
      case 5:
        return 'break' === id || 'local' === id || 'until' === id || 'while' === id;
      case 6:
        return 'elseif' === id || 'repeat' === id || 'return' === id;
      case 8:
        return 'function' === id;
    }
    return false;
  }

  function isUnary(token) {
    if (Punctuator === token.type) return '#-~'.indexOf(token.value) >= 0;
    if (Keyword === token.type) return 'not' === token.value;
    return false;
  }

  // @TODO this needs to be rethought.
  function isCallExpression(expression) {
    switch (expression.type) {
      case 'CallExpression':
      case 'TableCallExpression':
      case 'StringCallExpression':
        return true;
    }
    return false;
  }

  // Check if the token syntactically closes a block.

  function isBlockFollow(token) {
    if (EOF === token.type) return true;
    if (Keyword !== token.type) return false;
    switch (token.value) {
      case 'else': case 'elseif':
      case 'end': case 'until':
        return true;
      default:
        return false;
    }
  }

  // Scope
  // -----

  // Store each block scope as a an array of identifier names. Each scope is
  // stored in an FILO-array.
  var scopes
    // The current scope index
    , scopeDepth
    // A list of all global identifier nodes.
    , globals;

  // Create a new scope inheriting all declarations from the previous scope.
  function createScope() {
    var scope = Array.apply(null, scopes[scopeDepth++]);
    scopes.push(scope);
    if (options.onCreateScope) options.onCreateScope();
  }

  // Exit and remove the current scope.
  function destroyScope() {
    var scope = scopes.pop();
    scopeDepth--;
    if (options.onDestroyScope) options.onDestroyScope();
  }

  // Add identifier name to the current scope if it doesnt already exist.
  function scopeIdentifierName(name) {
    if (-1 !== indexOf(scopes[scopeDepth], name)) return;
    scopes[scopeDepth].push(name);
  }

  // Add identifier to the current scope
  function scopeIdentifier(node) {
    scopeIdentifierName(node.name);
    attachScope(node, true);
  }

  // Attach scope information to node. If the node is global, store it in the
  // globals array so we can return the information to the user.
  function attachScope(node, isLocal) {
    if (!isLocal && -1 === indexOfObject(globals, 'name', node.name))
      globals.push(node);

    node.isLocal = isLocal;
  }

  // Is the identifier name available in this scope.
  function scopeHasName(name) {
    return (-1 !== indexOf(scopes[scopeDepth], name));
  }

  // Location tracking
  // -----------------
  //
  // Locations are stored in FILO-array as a `Marker` object consisting of both
  // `loc` and `range` data. Once a `Marker` is popped off the list an end
  // location is added and the data is attached to a syntax node.

  var locations = []
    , trackLocations;

  function createLocationMarker() {
    return new Marker(token);
  }

  function Marker(token) {
    if (options.locations) {
      this.loc = {
          start: {
            line: token.line
          , column: token.range[0] - token.lineStart
        }
        , end: {
            line: 0
          , column: 0
        }
      };
    }
    if (options.ranges) this.range = [token.range[0], 0];
  }

  // Complete the location data stored in the `Marker` by adding the location
  // of the *previous token* as an end location.
  Marker.prototype.complete = function() {
    if (options.locations) {
      this.loc.end.line = previousToken.line;
      this.loc.end.column = previousToken.range[1] - previousToken.lineStart;
    }
    if (options.ranges) {
      this.range[1] = previousToken.range[1];
    }
  };

  // Create a new `Marker` and add it to the FILO-array.
  function markLocation() {
    if (trackLocations) locations.push(createLocationMarker());
  }

  // Push an arbitrary `Marker` object onto the FILO-array.
  function pushLocation(marker) {
    if (trackLocations) locations.push(marker);
  }

  // Parse functions
  // ---------------

  // Chunk is the main program object. Syntactically it's the same as a block.
  //
  //     chunk ::= block

  function parseChunk() {
    next();
    markLocation();
    if (options.scope) createScope();
    var body = parseBlock();
    if (options.scope) destroyScope();
    if (EOF !== token.type) unexpected(token);
    // If the body is empty no previousToken exists when finishNode runs.
    if (trackLocations && !body.length) previousToken = token;
    return finishNode(ast.chunk(body));
  }

  // A block contains a list of statements with an optional return statement
  // as its last statement.
  //
  //     block ::= {stat} [retstat]

  function parseBlock(terminator) {
    var block = []
      , statement;

    while (!isBlockFollow(token)) {
      // Return has to be the last statement in a block.
      if ('return' === token.value) {
        block.push(parseStatement());
        break;
      }
      statement = parseStatement();
      // Statements are only added if they are returned, this allows us to
      // ignore some statements, such as EmptyStatement.
      if (statement) block.push(statement);
    }

    // Doesn't really need an ast node
    return block;
  }

  // There are two types of statements, simple and compound.
  //
  //     statement ::= break | goto | do | while | repeat | return
  //          | if | for | function | local | label | assignment
  //          | functioncall | ';'

  function parseStatement() {
    markLocation();
    if (Keyword === token.type) {
      switch (token.value) {
        case 'local':    next(); return parseLocalStatement();
        case 'if':       next(); return parseIfStatement();
        case 'return':   next(); return parseReturnStatement();
        case 'function': next();
          var name = parseFunctionName();
          return parseFunctionDeclaration(name);
        case 'while':    next(); return parseWhileStatement();
        case 'for':      next(); return parseForStatement();
        case 'repeat':   next(); return parseRepeatStatement();
        case 'break':    next(); return parseBreakStatement();
        case 'do':       next(); return parseDoStatement();
        case 'goto':     next(); return parseGotoStatement();
      }
    }

    if (Punctuator === token.type) {
      if (consume('::')) return parseLabelStatement();
    }
    // Assignments memorizes the location and pushes it manually for wrapper
    // nodes. Additionally empty `;` statements should not mark a location.
    if (trackLocations) locations.pop();

    // When a `;` is encounted, simply eat it without storing it.
    if (consume(';')) return;

    return parseAssignmentOrCallStatement();
  }

  // ## Statements

  //     label ::= '::' Name '::'

  function parseLabelStatement() {
    var name = token.value
      , label = parseIdentifier();

    if (options.scope) {
      scopeIdentifierName('::' + name + '::');
      attachScope(label, true);
    }

    expect('::');
    return finishNode(ast.labelStatement(label));
  }

  //     break ::= 'break'

  function parseBreakStatement() {
    return finishNode(ast.breakStatement());
  }

  //     goto ::= 'goto' Name

  function parseGotoStatement() {
    var name = token.value
      , label = parseIdentifier();

    return finishNode(ast.gotoStatement(label));
  }

  //     do ::= 'do' block 'end'

  function parseDoStatement() {
    if (options.scope) createScope();
    var body = parseBlock();
    if (options.scope) destroyScope();
    expect('end');
    return finishNode(ast.doStatement(body));
  }

  //     while ::= 'while' exp 'do' block 'end'

  function parseWhileStatement() {
    var condition = parseExpectedExpression();
    expect('do');
    if (options.scope) createScope();
    var body = parseBlock();
    if (options.scope) destroyScope();
    expect('end');
    return finishNode(ast.whileStatement(condition, body));
  }

  //     repeat ::= 'repeat' block 'until' exp

  function parseRepeatStatement() {
    if (options.scope) createScope();
    var body = parseBlock();
    expect('until');
    var condition = parseExpectedExpression();
    if (options.scope) destroyScope();
    return finishNode(ast.repeatStatement(condition, body));
  }

  //     retstat ::= 'return' [exp {',' exp}] [';']

  function parseReturnStatement() {
    var expressions = [];

    if ('end' !== token.value) {
      var expression = parseExpression();
      if (null != expression) expressions.push(expression);
      while (consume(',')) {
        expression = parseExpectedExpression();
        expressions.push(expression);
      }
      consume(';'); // grammar tells us ; is optional here.
    }
    return finishNode(ast.returnStatement(expressions));
  }

  //     if ::= 'if' exp 'then' block {elif} ['else' block] 'end'
  //     elif ::= 'elseif' exp 'then' block

  function parseIfStatement() {
    var clauses = []
      , condition
      , body
      , marker;

    // IfClauses begin at the same location as the parent IfStatement.
    // It ends at the start of `end`, `else`, or `elseif`.
    if (trackLocations) {
      marker = locations[locations.length - 1];
      locations.push(marker);
    }
    condition = parseExpectedExpression();
    expect('then');
    if (options.scope) createScope();
    body = parseBlock();
    if (options.scope) destroyScope();
    clauses.push(finishNode(ast.ifClause(condition, body)));

    if (trackLocations) marker = createLocationMarker();
    while (consume('elseif')) {
      pushLocation(marker);
      condition = parseExpectedExpression();
      expect('then');
      if (options.scope) createScope();
      body = parseBlock();
      if (options.scope) destroyScope();
      clauses.push(finishNode(ast.elseifClause(condition, body)));
      if (trackLocations) marker = createLocationMarker();
    }

    if (consume('else')) {
      // Include the `else` in the location of ElseClause.
      if (trackLocations) {
        marker = new Marker(previousToken);
        locations.push(marker);
      }
      if (options.scope) createScope();
      body = parseBlock();
      if (options.scope) destroyScope();
      clauses.push(finishNode(ast.elseClause(body)));
    }

    expect('end');
    return finishNode(ast.ifStatement(clauses));
  }

  // There are two types of for statements, generic and numeric.
  //
  //     for ::= Name '=' exp ',' exp [',' exp] 'do' block 'end'
  //     for ::= namelist 'in' explist 'do' block 'end'
  //     namelist ::= Name {',' Name}
  //     explist ::= exp {',' exp}

  function parseForStatement() {
    var variable = parseIdentifier()
      , body;

    // The start-identifier is local.

    if (options.scope) {
      createScope();
      scopeIdentifier(variable);
    }

    // If the first expression is followed by a `=` punctuator, this is a
    // Numeric For Statement.
    if (consume('=')) {
      // Start expression
      var start = parseExpectedExpression();
      expect(',');
      // End expression
      var end = parseExpectedExpression();
      // Optional step expression
      var step = consume(',') ? parseExpectedExpression() : null;

      expect('do');
      body = parseBlock();
      expect('end');
      if (options.scope) destroyScope();

      return finishNode(ast.forNumericStatement(variable, start, end, step, body));
    }
    // If not, it's a Generic For Statement
    else {
      // The namelist can contain one or more identifiers.
      var variables = [variable];
      while (consume(',')) {
        variable = parseIdentifier();
        // Each variable in the namelist is locally scoped.
        if (options.scope) scopeIdentifier(variable);
        variables.push(variable);
      }
      expect('in');
      var iterators = [];

      // One or more expressions in the explist.
      do {
        var expression = parseExpectedExpression();
        iterators.push(expression);
      } while (consume(','));

      expect('do');
      body = parseBlock();
      expect('end');
      if (options.scope) destroyScope();

      return finishNode(ast.forGenericStatement(variables, iterators, body));
    }
  }

  // Local statements can either be variable assignments or function
  // definitions. If a function definition is found, it will be delegated to
  // `parseFunctionDeclaration()` with the isLocal flag.
  //
  // This AST structure might change into a local assignment with a function
  // child.
  //
  //     local ::= 'local' 'function' Name funcdecl
  //        | 'local' Name {',' Name} ['=' exp {',' exp}]

  function parseLocalStatement() {
    var name;

    if (Identifier === token.type) {
      var variables = []
        , init = [];

      do {
        name = parseIdentifier();

        variables.push(name);
      } while (consume(','));

      if (consume('=')) {
        do {
          var expression = parseExpectedExpression();
          init.push(expression);
        } while (consume(','));
      }

      // Declarations doesn't exist before the statement has been evaluated.
      // Therefore assignments can't use their declarator. And the identifiers
      // shouldn't be added to the scope until the statement is complete.
      if (options.scope) {
        for (var i = 0, l = variables.length; i < l; i++) {
          scopeIdentifier(variables[i]);
        }
      }

      return finishNode(ast.localStatement(variables, init));
    }
    if (consume('function')) {
      name = parseIdentifier();

      if (options.scope) {
        scopeIdentifier(name);
        createScope();
      }

      // MemberExpressions are not allowed in local function statements.
      return parseFunctionDeclaration(name, true);
    } else {
      raiseUnexpectedToken('<name>', token);
    }
  }

  function validateVar(node) {
    // @TODO we need something not dependent on the exact AST used. see also isCallExpression()
    if (node.inParens || (['Identifier', 'MemberExpression', 'IndexExpression'].indexOf(node.type) === -1)) {
      raise(token, errors.invalidVar, token.value);
    }
  }

  //     assignment ::= varlist '=' explist
  //     var ::= Name | prefixexp '[' exp ']' | prefixexp '.' Name
  //     varlist ::= var {',' var}
  //     explist ::= exp {',' exp}
  //
  //     call ::= callexp
  //     callexp ::= prefixexp args | prefixexp ':' Name args

  function parseAssignmentOrCallStatement() {
    // Keep a reference to the previous token for better error messages in case
    // of invalid statement
    var previous = token
      , expression, marker;

    if (trackLocations) marker = createLocationMarker();
    expression = parsePrefixExpression();

    if (null == expression) return unexpected(token);
    if (',='.indexOf(token.value) >= 0) {
      var variables = [expression]
        , init = []
        , exp;

      validateVar(expression);
      while (consume(',')) {
        exp = parsePrefixExpression();
        if (null == exp) raiseUnexpectedToken('<expression>', token);
        validateVar(exp);
        variables.push(exp);
      }
      expect('=');
      do {
        exp = parseExpectedExpression();
        init.push(exp);
      } while (consume(','));

      pushLocation(marker);
      return finishNode(ast.assignmentStatement(variables, init));
    }
    if (isCallExpression(expression)) {
      pushLocation(marker);
      return finishNode(ast.callStatement(expression));
    }
    // The prefix expression was neither part of an assignment or a
    // callstatement, however as it was valid it's been consumed, so raise
    // the exception on the previous token to provide a helpful message.
    return unexpected(previous);
  }



  // ### Non-statements

  //     Identifier ::= Name

  function parseIdentifier() {
    markLocation();
    var identifier = token.value;
    if (Identifier !== token.type) raiseUnexpectedToken('<name>', token);
    next();
    return finishNode(ast.identifier(identifier));
  }

  // Parse the functions parameters and body block. The name should already
  // have been parsed and passed to this declaration function. By separating
  // this we allow for anonymous functions in expressions.
  //
  // For local functions there's a boolean parameter which needs to be set
  // when parsing the declaration.
  //
  //     funcdecl ::= '(' [parlist] ')' block 'end'
  //     parlist ::= Name {',' Name} | [',' '...'] | '...'

  function parseFunctionDeclaration(name, isLocal) {
    var parameters = [];
    expect('(');

    // The declaration has arguments
    if (!consume(')')) {
      // Arguments are a comma separated list of identifiers, optionally ending
      // with a vararg.
      while (true) {
        if (Identifier === token.type) {
          var parameter = parseIdentifier();
          // Function parameters are local.
          if (options.scope) scopeIdentifier(parameter);

          parameters.push(parameter);

          if (consume(',')) continue;
          else if (consume(')')) break;
        }
        // No arguments are allowed after a vararg.
        else if (VarargLiteral === token.type) {
          parameters.push(parsePrimaryExpression());
          expect(')');
          break;
        } else {
          raiseUnexpectedToken('<name> or \'...\'', token);
        }
      }
    }

    var body = parseBlock();
    expect('end');
    if (options.scope) destroyScope();

    isLocal = isLocal || false;
    return finishNode(ast.functionStatement(name, parameters, isLocal, body));
  }

  // Parse the function name as identifiers and member expressions.
  //
  //     Name {'.' Name} [':' Name]

  function parseFunctionName() {
    var base, name, marker;

    if (trackLocations) marker = createLocationMarker();
    base = parseIdentifier();

    if (options.scope) {
      attachScope(base, scopeHasName(base.name));
      createScope();
    }

    while (consume('.')) {
      pushLocation(marker);
      name = parseIdentifier();
      base = finishNode(ast.memberExpression(base, '.', name));
    }

    if (consume(':')) {
      pushLocation(marker);
      name = parseIdentifier();
      base = finishNode(ast.memberExpression(base, ':', name));
      if (options.scope) scopeIdentifierName('self');
    }

    return base;
  }

  //     tableconstructor ::= '{' [fieldlist] '}'
  //     fieldlist ::= field {fieldsep field} fieldsep
  //     field ::= '[' exp ']' '=' exp | Name = 'exp' | exp
  //
  //     fieldsep ::= ',' | ';'

  function parseTableConstructor() {
    var fields = []
      , key, value;

    while (true) {
      markLocation();
      if (Punctuator === token.type && consume('[')) {
        key = parseExpectedExpression();
        expect(']');
        expect('=');
        value = parseExpectedExpression();
        fields.push(finishNode(ast.tableKey(key, value)));
      } else if (Identifier === token.type) {
        if ('=' === lookahead.value) {
          key = parseIdentifier();
          next();
          value = parseExpectedExpression();
          fields.push(finishNode(ast.tableKeyString(key, value)));
        } else {
          value = parseExpectedExpression();
          fields.push(finishNode(ast.tableValue(value)));
        }
      } else {
        if (null == (value = parseExpression())) {
          locations.pop();
          break;
        }
        fields.push(finishNode(ast.tableValue(value)));
      }
      if (',;'.indexOf(token.value) >= 0) {
        next();
        continue;
      }
      break;
    }
    expect('}');
    return finishNode(ast.tableConstructorExpression(fields));
  }

  // Expression parser
  // -----------------
  //
  // Expressions are evaluated and always return a value. If nothing is
  // matched null will be returned.
  //
  //     exp ::= (unop exp | primary | prefixexp ) { binop exp }
  //
  //     primary ::= nil | false | true | Number | String | '...'
  //          | functiondef | tableconstructor
  //
  //     prefixexp ::= (Name | '(' exp ')' ) { '[' exp ']'
  //          | '.' Name | ':' Name args | args }
  //

  function parseExpression() {
    var expression = parseSubExpression(0);
    return expression;
  }

  // Parse an expression expecting it to be valid.

  function parseExpectedExpression() {
    var expression = parseExpression();
    if (null == expression) raiseUnexpectedToken('<expression>', token);
    else return expression;
  }


  // Return the precedence priority of the operator.
  //
  // As unary `-` can't be distinguished from binary `-`, unary precedence
  // isn't described in this table but in `parseSubExpression()` itself.
  //
  // As this function gets hit on every expression it's been optimized due to
  // the expensive CompareICStub which took ~8% of the parse time.

  function binaryPrecedence(operator) {
    var charCode = operator.charCodeAt(0)
      , length = operator.length;

    if (1 === length) {
      switch (charCode) {
        case 94: return 12; // ^
        case 42: case 47: case 37: return 10; // * / %
        case 43: case 45: return 9; // + -
        case 38: return 6; // &
        case 126: return 5; // ~
        case 124: return 4; // |
        case 60: case 62: return 3; // < >
      }
    } else if (2 === length) {
      switch (charCode) {
        case 47: return 10; // //
        case 46: return 8; // ..
        case 60: case 62:
            if('<<' === operator || '>>' === operator) return 7; // << >>
            return 3; // <= >=
        case 61: case 126: return 3; // == ~=
        case 111: return 1; // or
      }
    } else if (97 === charCode && 'and' === operator) return 2;
    return 0;
  }

  // Implement an operator-precedence parser to handle binary operator
  // precedence.
  //
  // We use this algorithm because it's compact, it's fast and Lua core uses
  // the same so we can be sure our expressions are parsed in the same manner
  // without excessive amounts of tests.
  //
  //     exp ::= (unop exp | primary | prefixexp ) { binop exp }

  function parseSubExpression(minPrecedence) {
    var operator = token.value
    // The left-hand side in binary operations.
      , expression, marker;

    if (trackLocations) marker = createLocationMarker();

    // UnaryExpression
    if (isUnary(token)) {
      markLocation();
      next();
      var argument = parseSubExpression(10);
      if (argument == null) raiseUnexpectedToken('<expression>', token);
      expression = finishNode(ast.unaryExpression(operator, argument));
    }
    if (null == expression) {
      // PrimaryExpression
      expression = parsePrimaryExpression();

      // PrefixExpression
      if (null == expression) {
        expression = parsePrefixExpression();
      }
    }
    // This is not a valid left hand expression.
    if (null == expression) return null;

    var precedence;
    while (true) {
      operator = token.value;

      precedence = (Punctuator === token.type || Keyword === token.type) ?
        binaryPrecedence(operator) : 0;

      if (precedence === 0 || precedence <= minPrecedence) break;
      // Right-hand precedence operators
      if ('^' === operator || '..' === operator) precedence--;
      next();
      var right = parseSubExpression(precedence);
      if (null == right) raiseUnexpectedToken('<expression>', token);
      // Push in the marker created before the loop to wrap its entirety.
      if (trackLocations) locations.push(marker);
      expression = finishNode(ast.binaryExpression(operator, expression, right));

    }
    return expression;
  }

  //     prefixexp ::= prefix {suffix}
  //     prefix ::= Name | '(' exp ')'
  //     suffix ::= '[' exp ']' | '.' Name | ':' Name args | args
  //
  //     args ::= '(' [explist] ')' | tableconstructor | String

  function parsePrefixExpression() {
    var base, name, marker;

    if (trackLocations) marker = createLocationMarker();

    // The prefix
    if (Identifier === token.type) {
      name = token.value;
      base = parseIdentifier();
      // Set the parent scope.
      if (options.scope) attachScope(base, scopeHasName(name));
    } else if (consume('(')) {
      base = parseExpectedExpression();
      expect(')');
      base.inParens = true; // XXX: quick and dirty. needed for validateVar
    } else {
      return null;
    }

    // The suffix
    var expression, identifier;
    while (true) {
      if (Punctuator === token.type) {
        switch (token.value) {
          case '[':
            pushLocation(marker);
            next();
            expression = parseExpectedExpression();
            base = finishNode(ast.indexExpression(base, expression));
            expect(']');
            break;
          case '.':
            pushLocation(marker);
            next();
            identifier = parseIdentifier();
            base = finishNode(ast.memberExpression(base, '.', identifier));
            break;
          case ':':
            pushLocation(marker);
            next();
            identifier = parseIdentifier();
            base = finishNode(ast.memberExpression(base, ':', identifier));
            // Once a : is found, this has to be a CallExpression, otherwise
            // throw an error.
            pushLocation(marker);
            base = parseCallExpression(base);
            break;
          case '(': case '{': // args
            pushLocation(marker);
            base = parseCallExpression(base);
            break;
          default:
            return base;
        }
      } else if (StringLiteral === token.type) {
        pushLocation(marker);
        base = parseCallExpression(base);
      } else {
        break;
      }
    }

    return base;
  }

  //     args ::= '(' [explist] ')' | tableconstructor | String

  function parseCallExpression(base) {
    if (Punctuator === token.type) {
      switch (token.value) {
        case '(':
          next();

          // List of expressions
          var expressions = [];
          var expression = parseExpression();
          if (null != expression) expressions.push(expression);
          while (consume(',')) {
            expression = parseExpectedExpression();
            expressions.push(expression);
          }

          expect(')');
          return finishNode(ast.callExpression(base, expressions));

        case '{':
          markLocation();
          next();
          var table = parseTableConstructor();
          return finishNode(ast.tableCallExpression(base, table));
      }
    } else if (StringLiteral === token.type) {
      return finishNode(ast.stringCallExpression(base, parsePrimaryExpression()));
    }

    raiseUnexpectedToken('function arguments', token);
  }

  //     primary ::= String | Numeric | nil | true | false
  //          | functiondef | tableconstructor | '...'

  function parsePrimaryExpression() {
    var literals = StringLiteral | NumericLiteral | BooleanLiteral | NilLiteral | VarargLiteral
      , value = token.value
      , type = token.type
      , marker;

    if (trackLocations) marker = createLocationMarker();

    if (type & literals) {
      pushLocation(marker);
      var raw = input.slice(token.range[0], token.range[1]);
      next();
      return finishNode(ast.literal(type, value, raw));
    } else if (Keyword === type && 'function' === value) {
      pushLocation(marker);
      next();
      if (options.scope) createScope();
      return parseFunctionDeclaration(null);
    } else if (consume('{')) {
      pushLocation(marker);
      return parseTableConstructor();
    }
  }

  // Parser
  // ------

  // Export the main parser.
  //
  //   - `wait` Hold parsing until end() is called. Defaults to false
  //   - `comments` Store comments. Defaults to true.
  //   - `scope` Track identifier scope. Defaults to false.
  //   - `locations` Store location information. Defaults to false.
  //   - `ranges` Store the start and end character locations. Defaults to
  //     false.
  //   - `onCreateNode` Callback which will be invoked when a syntax node is
  //     created.
  //   - `onCreateScope` Callback which will be invoked when a new scope is
  //     created.
  //   - `onDestroyScope` Callback which will be invoked when the current scope
  //     is destroyed.
  //
  // Example:
  //
  //     var parser = require('luaparser');
  //     parser.parse('i = 0');

  exports.parse = parse;

  function parse(_input, _options) {
    if ('undefined' === typeof _options && 'object' === typeof _input) {
      _options = _input;
      _input = undefined;
    }
    if (!_options) _options = {};

    input = _input || '';
    options = extend(defaultOptions, _options);

    // Rewind the lexer
    index = 0;
    line = 1;
    lineStart = 0;
    length = input.length;
    // When tracking identifier scope, initialize with an empty scope.
    scopes = [[]];
    scopeDepth = 0;
    globals = [];
    locations = [];

    if (options.comments) comments = [];
    if (!options.wait) return end();
    return exports;
  }

  // Write to the source code buffer without beginning the parse.
  exports.write = write;

  function write(_input) {
    input += String(_input);
    length = input.length;
    return exports;
  }

  // Send an EOF and begin parsing.
  exports.end = end;

  function end(_input) {
    if ('undefined' !== typeof _input) write(_input);

    // Ignore shebangs.
    if (input && input.substr(0, 2) === '#!') input = input.replace(/^.*/, function (line) {
      return line.replace(/./g, ' ');
    });

    length = input.length;
    trackLocations = options.locations || options.ranges;
    // Initialize with a lookahead token.
    lookahead = lex();

    var chunk = parseChunk();
    if (options.comments) chunk.comments = comments;
    if (options.scope) chunk.globals = globals;

    if (locations.length > 0)
      throw new Error('Location tracking failed. This is most likely a bug in luaparse');

    return chunk;
  }

}));
/* vim: set sw=2 ts=2 et tw=79 : */


/***/ }),

/***/ 1418:
/***/ (function(module, exports, __nccwpck_require__) {

/* module decorator */ module = __nccwpck_require__.nmd(module);
/* global exports:true, module:true, require:true, define:true, global:true */

(function (root, name, factory) {
  'use strict';

  // Used to determine if values are of the language type `Object`
  var objectTypes = {
        'function': true
      , 'object': true
    }
    // Detect free variable `exports`
    , freeExports = objectTypes[typeof exports] && exports && !exports.nodeType && exports
    // Detect free variable `module`
    , freeModule = objectTypes["object"] && module && !module.nodeType && module
    // Detect free variable `global`, from Node.js or Browserified code, and
    // use it as `window`
    , freeGlobal = freeExports && freeModule && typeof global === 'object' && global
    // Detect the popular CommonJS extension `module.exports`
    , moduleExports = freeModule && freeModule.exports === freeExports && freeExports;

  /* istanbul ignore else */
  if (freeGlobal && (freeGlobal.global === freeGlobal ||
                     /* istanbul ignore next */ freeGlobal.window === freeGlobal ||
                     /* istanbul ignore next */ freeGlobal.self === freeGlobal)) {
    root = freeGlobal;
  }

  // Some AMD build optimizers, like r.js, check for specific condition
  // patterns like the following:
  /* istanbul ignore if */
  if (typeof define === 'function' &&
      /* istanbul ignore next */ typeof define.amd === 'object' &&
      /* istanbul ignore next */ define.amd) {
    // defined as an anonymous module.
    define(['exports'], factory);
    // In case the source has been processed and wrapped in a define module use
    // the supplied `exports` object.
    if (freeExports && moduleExports) factory(freeModule.exports);
  }
  // check for `exports` after `define` in case a build optimizer adds an
  // `exports` object
  else /* istanbul ignore else */ if (freeExports && freeModule) {
    // in Node.js or RingoJS v0.8.0+
    /* istanbul ignore else */
    if (moduleExports) factory(freeModule.exports);
    // in RingoJS v0.7.0-
    else factory(freeExports);
  }
  // in a browser or Rhino
  else {
    factory((root[name] = {}));
  }
}(this, 'luaparse', function (exports) {
  'use strict';

  exports.version = '0.2.1';

  var input, options, length, features;

  // Options can be set either globally on the parser object through
  // defaultOptions, or during the parse call.
  var defaultOptions = exports.defaultOptions = {
    // Explicitly tell the parser when the input ends.
      wait: false
    // Store comments as an array in the chunk object.
    , comments: true
    // Track identifier scopes by adding an isLocal attribute to each
    // identifier-node.
    , scope: false
    // Store location information on each syntax node as
    // `loc: { start: { line, column }, end: { line, column } }`.
    , locations: false
    // Store the start and end character locations on each syntax node as
    // `range: [start, end]`.
    , ranges: false
    // A callback which will be invoked when a syntax node has been completed.
    // The node which has been created will be passed as the only parameter.
    , onCreateNode: null
    // A callback which will be invoked when a new scope is created.
    , onCreateScope: null
    // A callback which will be invoked when the current scope is destroyed.
    , onDestroyScope: null
    // A callback which will be invoked when a local variable is declared in the current scope.
    // The variable's name will be passed as the only parameter
    , onLocalDeclaration: null
    // The version of Lua targeted by the parser (string; allowed values are
    // '5.1', '5.2', '5.3').
    , luaVersion: '5.1'
  };

  // The available tokens expressed as enum flags so they can be checked with
  // bitwise operations.

  var EOF = 1, StringLiteral = 2, Keyword = 4, Identifier = 8
    , NumericLiteral = 16, Punctuator = 32, BooleanLiteral = 64
    , NilLiteral = 128, VarargLiteral = 256;

  exports.tokenTypes = { EOF: EOF, StringLiteral: StringLiteral
    , Keyword: Keyword, Identifier: Identifier, NumericLiteral: NumericLiteral
    , Punctuator: Punctuator, BooleanLiteral: BooleanLiteral
    , NilLiteral: NilLiteral, VarargLiteral: VarargLiteral
  };

  // As this parser is a bit different from luas own, the error messages
  // will be different in some situations.

  var errors = exports.errors = {
      unexpected: 'unexpected %1 \'%2\' near \'%3\''
    , unexpectedEOF: 'unexpected symbol near \'<eof>\''
    , expected: '\'%1\' expected near \'%2\''
    , expectedToken: '%1 expected near \'%2\''
    , unfinishedString: 'unfinished string near \'%1\''
    , malformedNumber: 'malformed number near \'%1\''
    , decimalEscapeTooLarge: 'decimal escape too large near \'%1\''
    , invalidEscape: 'invalid escape sequence near \'%1\''
    , hexadecimalDigitExpected: 'hexadecimal digit expected near \'%1\''
    , braceExpected: 'missing \'%1\' near \'%2\''
    , tooLargeCodepoint: 'UTF-8 value too large near \'%1\''
    , unfinishedLongString: 'unfinished long string (starting at line %1) near \'%2\''
    , unfinishedLongComment: 'unfinished long comment (starting at line %1) near \'%2\''
    , ambiguousSyntax: 'ambiguous syntax (function call x new statement) near \'%1\''
    , noLoopToBreak: 'no loop to break near \'%1\''
    , labelAlreadyDefined: 'label \'%1\' already defined on line %2'
    , labelNotVisible: 'no visible label \'%1\' for <goto>'
    , gotoJumpInLocalScope: '<goto %1> jumps into the scope of local \'%2\''
    , cannotUseVararg: 'cannot use \'...\' outside a vararg function near \'%1\''
  };

  // ### Abstract Syntax Tree
  //
  // The default AST structure is inspired by the Mozilla Parser API but can
  // easily be customized by overriding these functions.

  var ast = exports.ast = {
      labelStatement: function(label) {
      return {
          type: 'LabelStatement'
        , label: label
      };
    }

    , breakStatement: function() {
      return {
          type: 'BreakStatement'
      };
    }

    , gotoStatement: function(label) {
      return {
          type: 'GotoStatement'
        , label: label
      };
    }

    , returnStatement: function(args) {
      return {
          type: 'ReturnStatement'
        , 'arguments': args
      };
    }

    , ifStatement: function(clauses) {
      return {
          type: 'IfStatement'
        , clauses: clauses
      };
    }
    , ifClause: function(condition, body) {
      return {
          type: 'IfClause'
        , condition: condition
        , body: body
      };
    }
    , elseifClause: function(condition, body) {
      return {
          type: 'ElseifClause'
        , condition: condition
        , body: body
      };
    }
    , elseClause: function(body) {
      return {
          type: 'ElseClause'
        , body: body
      };
    }

    , whileStatement: function(condition, body) {
      return {
          type: 'WhileStatement'
        , condition: condition
        , body: body
      };
    }

    , doStatement: function(body) {
      return {
          type: 'DoStatement'
        , body: body
      };
    }

    , repeatStatement: function(condition, body) {
      return {
          type: 'RepeatStatement'
        , condition: condition
        , body: body
      };
    }

    , localStatement: function(variables, init) {
      return {
          type: 'LocalStatement'
        , variables: variables
        , init: init
      };
    }

    , assignmentStatement: function(variables, init) {
      return {
          type: 'AssignmentStatement'
        , variables: variables
        , init: init
      };
    }

    , callStatement: function(expression) {
      return {
          type: 'CallStatement'
        , expression: expression
      };
    }

    , functionStatement: function(identifier, parameters, isLocal, body) {
      return {
          type: 'FunctionDeclaration'
        , identifier: identifier
        , isLocal: isLocal
        , parameters: parameters
        , body: body
      };
    }

    , forNumericStatement: function(variable, start, end, step, body) {
      return {
          type: 'ForNumericStatement'
        , variable: variable
        , start: start
        , end: end
        , step: step
        , body: body
      };
    }

    , forGenericStatement: function(variables, iterators, body) {
      return {
          type: 'ForGenericStatement'
        , variables: variables
        , iterators: iterators
        , body: body
      };
    }

    , chunk: function(body) {
      return {
          type: 'Chunk'
        , body: body
      };
    }

    , identifier: function(name) {
      return {
          type: 'Identifier'
        , name: name
      };
    }

    , literal: function(type, value, raw) {
      type = (type === StringLiteral) ? 'StringLiteral'
        : (type === NumericLiteral) ? 'NumericLiteral'
        : (type === BooleanLiteral) ? 'BooleanLiteral'
        : (type === NilLiteral) ? 'NilLiteral'
        : 'VarargLiteral';

      return {
          type: type
        , value: value
        , raw: raw
      };
    }

    , tableKey: function(key, value) {
      return {
          type: 'TableKey'
        , key: key
        , value: value
      };
    }
    , tableKeyString: function(key, value) {
      return {
          type: 'TableKeyString'
        , key: key
        , value: value
      };
    }
    , tableValue: function(value) {
      return {
          type: 'TableValue'
        , value: value
      };
    }


    , tableConstructorExpression: function(fields) {
      return {
          type: 'TableConstructorExpression'
        , fields: fields
      };
    }
    , binaryExpression: function(operator, left, right) {
      var type = ('and' === operator || 'or' === operator) ?
        'LogicalExpression' :
        'BinaryExpression';

      return {
          type: type
        , operator: operator
        , left: left
        , right: right
      };
    }
    , unaryExpression: function(operator, argument) {
      return {
          type: 'UnaryExpression'
        , operator: operator
        , argument: argument
      };
    }
    , memberExpression: function(base, indexer, identifier) {
      return {
          type: 'MemberExpression'
        , indexer: indexer
        , identifier: identifier
        , base: base
      };
    }

    , indexExpression: function(base, index) {
      return {
          type: 'IndexExpression'
        , base: base
        , index: index
      };
    }

    , indexesExpression: function(base, indexes) {
      return {
        type: 'IndexesExpression'
        , base: base
        , indexes: indexes
      };
    }

    , callExpression: function(base, args) {
      return {
          type: 'CallExpression'
        , base: base
        , 'arguments': args
      };
    }

    , tableCallExpression: function(base, args) {
      return {
          type: 'TableCallExpression'
        , base: base
        , 'arguments': args
      };
    }

    , stringCallExpression: function(base, argument) {
      return {
          type: 'StringCallExpression'
        , base: base
        , argument: argument
      };
    }

    , comment: function(value, raw) {
      return {
          type: 'Comment'
        , value: value
        , raw: raw
      };
    }

    , shortFunctionDefinition: function(parameters, expression) {
      return {
        type: 'ShortFunctionDefinition'
        , parameters: parameters
        , expression: expression
      };
    }
  };

  // Wrap up the node object.

  function finishNode(node) {
    // Pop a `Marker` off the location-array and attach its location data.
    if (trackLocations) {
      var location = locations.pop();
      location.complete();
      location.bless(node);
    }
    if (options.onCreateNode) options.onCreateNode(node);
    return node;
  }


  // Helpers
  // -------

  var slice = Array.prototype.slice
    , toString = Object.prototype.toString
    ;

  var indexOf = /* istanbul ignore next */ function (array, element) {
    for (var i = 0, length = array.length; i < length; ++i) {
      if (array[i] === element) return i;
    }
    return -1;
  };

  /* istanbul ignore else */
  if (Array.prototype.indexOf)
    indexOf = function (array, element) {
      return array.indexOf(element);
    };

  // Iterate through an array of objects and return the index of an object
  // with a matching property.

  function indexOfObject(array, property, element) {
    for (var i = 0, length = array.length; i < length; ++i) {
      if (array[i][property] === element) return i;
    }
    return -1;
  }

  // A sprintf implementation using %index (beginning at 1) to input
  // arguments in the format string.
  //
  // Example:
  //
  //     // Unexpected function in token
  //     sprintf('Unexpected %2 in %1.', 'token', 'function');

  function sprintf(format) {
    var args = slice.call(arguments, 1);
    format = format.replace(/%(\d)/g, function (match, index) {
      return '' + args[index - 1] || /* istanbul ignore next */ '';
    });
    return format;
  }

  // Polyfill for `Object.assign`.

  var assign = /* istanbul ignore next */ function (dest) {
    var args = slice.call(arguments, 1)
      , src, prop;

    for (var i = 0, length = args.length; i < length; ++i) {
      src = args[i];
      for (prop in src)
        /* istanbul ignore else */
        if (Object.prototype.hasOwnProperty.call(src, prop)) {
          dest[prop] = src[prop];
        }
    }

    return dest;
  };

  /* istanbul ignore else */
  if (Object.assign)
    assign = Object.assign;

  // ### Error functions

  // XXX: Eliminate this function and change the error type to be different from SyntaxError.
  // This will unfortunately be a breaking change, because some downstream users depend
  // on the error thrown being an instance of SyntaxError. For example, the Ace editor:
  // <https://github.com/ajaxorg/ace/blob/4c7e5eb3f5d5ca9434847be51834a4e41661b852/lib/ace/mode/lua_worker.js#L55>

  function fixupError(e) {
    /* istanbul ignore if */
    if (!Object.create)
      return e;
    return Object.create(e, {
      'line': { 'writable': true, value: e.line },
      'index': { 'writable': true, value: e.index },
      'column': { 'writable': true, value: e.column }
    });
  }

  // #### Raise an exception.
  //
  // Raise an exception by passing a token, a string format and its paramters.
  //
  // The passed tokens location will automatically be added to the error
  // message if it exists, if not it will default to the lexers current
  // position.
  //
  // Example:
  //
  //     // [1:0] expected [ near (
  //     raise(token, "expected %1 near %2", '[', token.value);

  function raise(token) {
    var message = sprintf.apply(null, slice.call(arguments, 1))
      , error, col;

    if (token === null || typeof token.line === 'undefined') {
      col = index - lineStart + 1;
      error = fixupError(new SyntaxError(sprintf('[%1:%2] %3', line, col, message)));
      error.index = index;
      error.line = line;
      error.column = col;
    } else {
      col = token.range[0] - token.lineStart;
      error = fixupError(new SyntaxError(sprintf('[%1:%2] %3', token.line, col, message)));
      error.line = token.line;
      error.index = token.range[0];
      error.column = col;
    }
    throw error;
  }

  // #### Raise an unexpected token error.
  //
  // Example:
  //
  //     // expected <name> near '0'
  //     raiseUnexpectedToken('<name>', token);

  function raiseUnexpectedToken(type, token) {
    raise(token, errors.expectedToken, type, token.value);
  }

  // #### Raise a general unexpected error
  //
  // Usage should pass either a token object or a symbol string which was
  // expected. We can also specify a nearby token such as <eof>, this will
  // default to the currently active token.
  //
  // Example:
  //
  //     // Unexpected symbol 'end' near '<eof>'
  //     unexpected(token);
  //
  // If there's no token in the buffer it means we have reached <eof>.

  function unexpected(found) {
    var near = lookahead.value;
    if ('undefined' !== typeof found.type) {
      var type;
      switch (found.type) {
        case StringLiteral:   type = 'string';      break;
        case Keyword:         type = 'keyword';     break;
        case Identifier:      type = 'identifier';  break;
        case NumericLiteral:  type = 'number';      break;
        case Punctuator:      type = 'symbol';      break;
        case BooleanLiteral:  type = 'boolean';     break;
        case NilLiteral:
          return raise(found, errors.unexpected, 'symbol', 'nil', near);
        case EOF:
          return raise(found, errors.unexpectedEOF);
      }
      return raise(found, errors.unexpected, type, found.value, near);
    }
    return raise(found, errors.unexpected, 'symbol', found, near);
  }

  // Lexer
  // -----
  //
  // The lexer, or the tokenizer reads the input string character by character
  // and derives a token left-right. To be as efficient as possible the lexer
  // prioritizes the common cases such as identifiers. It also works with
  // character codes instead of characters as string comparisons was the
  // biggest bottleneck of the parser.
  //
  // If `options.comments` is enabled, all comments encountered will be stored
  // in an array which later will be appended to the chunk object. If disabled,
  // they will simply be disregarded.
  //
  // When the lexer has derived a valid token, it will be returned as an object
  // containing its value and as well as its position in the input string (this
  // is always enabled to provide proper debug messages).
  //
  // `lex()` starts lexing and returns the following token in the stream.

  var index
    , token
    , previousToken
    , lookahead
    , comments
    , tokenStart
    , line
    , lineStart;

  exports.lex = lex;

  function lex() {
    skipWhiteSpace();

    // Skip comments beginning with --
    while (45 === input.charCodeAt(index) &&
           45 === input.charCodeAt(index + 1)) {
      scanComment();
      skipWhiteSpace();
    }
    if (index >= length) return {
        type : EOF
      , value: '<eof>'
      , line: line
      , lineStart: lineStart
      , range: [index, index]
    };

    var charCode = input.charCodeAt(index)
      , next = input.charCodeAt(index + 1);

    // Memorize the range index where the token begins.
    tokenStart = index;
    if (isIdentifierStart(charCode)) return scanIdentifierOrKeyword();

    switch (charCode) {
      case 39: case 34: // '"
        return scanStringLiteral();

      case 48: case 49: case 50: case 51: case 52: case 53:
      case 54: case 55: case 56: case 57: // 0-9
        return scanNumericLiteral();

      case 46: // .
        // If the dot is followed by a digit it's a float.
        if (isDecDigit(next)) return scanNumericLiteral();
        if (46 === next) {
          if (46 === input.charCodeAt(index + 2)) return scanVarargLiteral();
          return scanPunctuator('..');
        }
        return scanPunctuator('.');

      case 61: // =
        if (61 === next) return scanPunctuator('==');
        return scanPunctuator('=');

      case 62: // >
        if (features.bitwiseOperators)
          if (62 === next) return scanPunctuator('>>');
        if (61 === next) return scanPunctuator('>=');
        return scanPunctuator('>');

      case 60: // <
        if (features.bitwiseOperators)
          if (60 === next) return scanPunctuator('<<');
        if (61 === next) return scanPunctuator('<=');
        return scanPunctuator('<');

      case 126: // ~
        if (61 === next) return scanPunctuator('~=');
        if (!features.bitwiseOperators)
          break;
        return scanPunctuator('~');

      case 33:
        if (61 === next) return scanPunctuator('!=');
        break;

      case 58: // :
        if (features.labels)
          if (58 === next) return scanPunctuator('::');
        return scanPunctuator(':');

      case 91: // [
        // Check for a multiline string, they begin with [= or [[
        if (91 === next || 61 === next) return scanLongStringLiteral();
        return scanPunctuator('[');

      case 47: // /
        // Check for integer division op (//)
        if (features.integerDivision)
          if (47 === next) return scanPunctuator('//');
        return scanPunctuator('/');

      case 38: // &
        if (!features.bitwiseOperators)
          break;
        /* fall through */

      case 124: // |

        /* fall through */
      case 42: case 94: case 37: case 44: case 123: case 125:
      case 93: case 40: case 41: case 59: case 35: case 45:
      case 43: // * ^ % , { } ] ( ) ; # - +
        return scanPunctuator(input.charAt(index));
    }

    return unexpected(input.charAt(index));
  }

  // Whitespace has no semantic meaning in lua so simply skip ahead while
  // tracking the encounted newlines. Any kind of eol sequence is counted as a
  // single line.

  function consumeEOL() {
    var charCode = input.charCodeAt(index)
      , peekCharCode = input.charCodeAt(index + 1);

    if (isLineTerminator(charCode)) {
      // Count \n\r and \r\n as one newline.
      if (10 === charCode && 13 === peekCharCode) ++index;
      if (13 === charCode && 10 === peekCharCode) ++index;
      ++line;
      lineStart = ++index;

      return true;
    }
    return false;
  }

  function skipWhiteSpace() {
    while (index < length) {
      var charCode = input.charCodeAt(index);
      if (isWhiteSpace(charCode)) {
        ++index;
      } else if (!consumeEOL()) {
        break;
      }
    }
  }

  function encodeUTF8(codepoint) {
    if (codepoint < 0x80) {
      return String.fromCharCode(codepoint);
    } else if (codepoint < 0x800) {
      return String.fromCharCode(
        0xc0 |  (codepoint >>  6)        ,
        0x80 | ( codepoint        & 0x3f)
      );
    } else if (codepoint < 0x10000) {
      return String.fromCharCode(
        0xe0 |  (codepoint >> 12)        ,
        0x80 | ((codepoint >>  6) & 0x3f),
        0x80 | ( codepoint        & 0x3f)
      );
    } else if (codepoint < 0x110000) {
      return String.fromCharCode(
        0xf0 |  (codepoint >> 18)        ,
        0x80 | ((codepoint >> 12) & 0x3f),
        0x80 | ((codepoint >>  6) & 0x3f),
        0x80 | ( codepoint        & 0x3f)
      );
    } else {
      return null;
    }
  }

  // This function takes a JavaScript string, encodes it in WTF-8 and
  // reinterprets the resulting code units as code points; i.e. it encodes
  // the string in what was the original meaning of WTF-8.
  //
  // For a detailed rationale, see the README.md file, section
  // "Note on character encodings".

  function fixupHighCharacters(s) {
    return s.replace(/[\ud800-\udbff][\udc00-\udfff]|[^\x00-\x7f]/g, function (m) {
      if (m.length === 1)
        return encodeUTF8(m.charCodeAt(0));
      return encodeUTF8(0x10000 + (((m.charCodeAt(0) & 0x3ff) << 10) | (m.charCodeAt(1) & 0x3ff)));
    });
  }

  // Identifiers, keywords, booleans and nil all look the same syntax wise. We
  // simply go through them one by one and defaulting to an identifier if no
  // previous case matched.

  function scanIdentifierOrKeyword() {
    var value, type;

    // Slicing the input string is prefered before string concatenation in a
    // loop for performance reasons.
    while (isIdentifierPart(input.charCodeAt(++index)));
    value = fixupHighCharacters(input.slice(tokenStart, index));

    // Decide on the token type and possibly cast the value.
    if (isKeyword(value)) {
      type = Keyword;
    } else if ('true' === value || 'false' === value) {
      type = BooleanLiteral;
      value = ('true' === value);
    } else if ('nil' === value) {
      type = NilLiteral;
      value = null;
    } else {
      type = Identifier;
    }

    return {
        type: type
      , value: value
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Once a punctuator reaches this function it should already have been
  // validated so we simply return it as a token.

  function scanPunctuator(value) {
    index += value.length;
    return {
        type: Punctuator
      , value: value
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // A vararg literal consists of three dots.

  function scanVarargLiteral() {
    index += 3;
    return {
        type: VarargLiteral
      , value: '...'
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Find the string literal by matching the delimiter marks used.

  function scanStringLiteral() {
    var delimiter = input.charCodeAt(index++)
      , beginLine = line
      , beginLineStart = lineStart
      , stringStart = index
      , string = ''
      , charCode;

    for (;;) {
      charCode = input.charCodeAt(index++);
      if (delimiter === charCode) break;
      // EOF or `\n` terminates a string literal. If we haven't found the
      // ending delimiter by now, raise an exception.
      if (index > length || isLineTerminator(charCode)) {
        string += input.slice(stringStart, index - 1);
        raise(null, errors.unfinishedString, String.fromCharCode(delimiter) + string);
      }
      if (92 === charCode) { // backslash
        string += fixupHighCharacters(input.slice(stringStart, index - 1)) + readEscapeSequence();
        stringStart = index;
      }
    }
    string += fixupHighCharacters(input.slice(stringStart, index - 1));

    return {
        type: StringLiteral
      , value: string
      , line: beginLine
      , lineStart: beginLineStart
      , lastLine: line
      , lastLineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Expect a multiline string literal and return it as a regular string
  // literal, if it doesn't validate into a valid multiline string, throw an
  // exception.

  function scanLongStringLiteral() {
    var beginLine = line
      , beginLineStart = lineStart
      , string = readLongString(false);
    // Fail if it's not a multiline literal.
    if (false === string) raise(token, errors.expected, '[', token.value);

    return {
        type: StringLiteral
      , value: fixupHighCharacters(string)
      , line: beginLine
      , lineStart: beginLineStart
      , lastLine: line
      , lastLineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Numeric literals will be returned as floating-point numbers instead of
  // strings. The raw value should be retrieved from slicing the input string
  // later on in the process.
  //
  // If a hexadecimal number is encountered, it will be converted.

  function scanNumericLiteral() {
    var character = input.charAt(index)
      , next = input.charAt(index + 1);

    var value = ('0' === character && 'xX'.indexOf(next || null) >= 0) ?
      readHexLiteral() : readDecLiteral();

    return {
        type: NumericLiteral
      , value: value
      , line: line
      , lineStart: lineStart
      , range: [tokenStart, index]
    };
  }

  // Lua hexadecimals have an optional fraction part and an optional binary
  // exoponent part. These are not included in JavaScript so we will compute
  // all three parts separately and then sum them up at the end of the function
  // with the following algorithm.
  //
  //     Digit := toDec(digit)
  //     Fraction := toDec(fraction) / 16 ^ fractionCount
  //     BinaryExp := 2 ^ binaryExp
  //     Number := ( Digit + Fraction ) * BinaryExp

  function readHexLiteral() {
    var fraction = 0 // defaults to 0 as it gets summed
      , binaryExponent = 1 // defaults to 1 as it gets multiplied
      , binarySign = 1 // positive
      , digit, fractionStart, exponentStart, digitStart;

    digitStart = index += 2; // Skip 0x part

    // A minimum of one hex digit is required.
    if (!isHexDigit(input.charCodeAt(index)))
      raise(null, errors.malformedNumber, input.slice(tokenStart, index));

    while (isHexDigit(input.charCodeAt(index))) ++index;
    // Convert the hexadecimal digit to base 10.
    digit = parseInt(input.slice(digitStart, index), 16);

    // Fraction part i optional.
    if ('.' === input.charAt(index)) {
      fractionStart = ++index;

      while (isHexDigit(input.charCodeAt(index))) ++index;
      fraction = input.slice(fractionStart, index);

      // Empty fraction parts should default to 0, others should be converted
      // 0.x form so we can use summation at the end.
      fraction = (fractionStart === index) ? 0
        : parseInt(fraction, 16) / Math.pow(16, index - fractionStart);
    }

    // Binary exponents are optional
    if ('pP'.indexOf(input.charAt(index) || null) >= 0) {
      ++index;

      // Sign part is optional and defaults to 1 (positive).
      if ('+-'.indexOf(input.charAt(index) || null) >= 0)
        binarySign = ('+' === input.charAt(index++)) ? 1 : -1;

      exponentStart = index;

      // The binary exponent sign requires a decimal digit.
      if (!isDecDigit(input.charCodeAt(index)))
        raise(null, errors.malformedNumber, input.slice(tokenStart, index));

      while (isDecDigit(input.charCodeAt(index))) ++index;
      binaryExponent = input.slice(exponentStart, index);

      // Calculate the binary exponent of the number.
      binaryExponent = Math.pow(2, binaryExponent * binarySign);
    }

    return (digit + fraction) * binaryExponent;
  }

  // Decimal numbers are exactly the same in Lua and in JavaScript, because of
  // this we check where the token ends and then parse it with native
  // functions.

  function readDecLiteral() {
    while (isDecDigit(input.charCodeAt(index))) ++index;
    // Fraction part is optional
    if ('.' === input.charAt(index)) {
      ++index;
      // Fraction part defaults to 0
      while (isDecDigit(input.charCodeAt(index))) ++index;
    }
    // Exponent part is optional.
    if ('eE'.indexOf(input.charAt(index) || null) >= 0) {
      ++index;
      // Sign part is optional.
      if ('+-'.indexOf(input.charAt(index) || null) >= 0) ++index;
      // An exponent is required to contain at least one decimal digit.
      if (!isDecDigit(input.charCodeAt(index)))
        raise(null, errors.malformedNumber, input.slice(tokenStart, index));

      while (isDecDigit(input.charCodeAt(index))) ++index;
    }

    return parseFloat(input.slice(tokenStart, index));
  }

  function readUnicodeEscapeSequence() {
    var sequenceStart = index++;

    if (input.charAt(index++) !== '{')
      raise(null, errors.braceExpected, '{', '\\' + input.slice(sequenceStart, index));
    if (!isHexDigit(input.charCodeAt(index)))
      raise(null, errors.hexadecimalDigitExpected, '\\' + input.slice(sequenceStart, index));

    while (input.charCodeAt(index) === 0x30) ++index;
    var escStart = index;

    while (isHexDigit(input.charCodeAt(index))) {
      ++index;
      if (index - escStart > 6)
        raise(null, errors.tooLargeCodepoint, '\\' + input.slice(sequenceStart, index));
    }

    var b = input.charAt(index++);
    if (b !== '}') {
      if ((b === '"') || (b === "'"))
        raise(null, errors.braceExpected, '}', '\\' + input.slice(sequenceStart, index--));
      else
        raise(null, errors.hexadecimalDigitExpected, '\\' + input.slice(sequenceStart, index));
    }

    var codepoint = parseInt(input.slice(escStart, index - 1), 16);

    codepoint = encodeUTF8(codepoint);
    if (codepoint === null) {
      raise(null, errors.tooLargeCodepoint, '\\' + input.slice(sequenceStart, index));
    }
    return codepoint;
  }

  // Translate escape sequences to the actual characters.
  function readEscapeSequence() {
    var sequenceStart = index;
    switch (input.charAt(index)) {
      // Lua allow the following escape sequences.
      case 'a': ++index; return '\x07';
      case 'n': ++index; return '\n';
      case 'r': ++index; return '\r';
      case 't': ++index; return '\t';
      case 'v': ++index; return '\x0b';
      case 'b': ++index; return '\b';
      case 'f': ++index; return '\f';

      // Backslash at the end of the line. We treat all line endings as equivalent,
      // and as representing the [LF] character (code 10). Lua 5.1 through 5.3
      // have been verified to behave the same way.
      case '\r':
      case '\n':
        consumeEOL();
        return '\n';

      case '0': case '1': case '2': case '3': case '4':
      case '5': case '6': case '7': case '8': case '9':
        // \ddd, where ddd is a sequence of up to three decimal digits.
        while (isDecDigit(input.charCodeAt(index)) && index - sequenceStart < 3) ++index;

        var ddd = parseInt(input.slice(sequenceStart, index), 10);
        if (ddd > 255) {
          raise(null, errors.decimalEscapeTooLarge, '\\' + ddd);
        }
        return String.fromCharCode(ddd);

      case 'z':
        if (features.skipWhitespaceEscape) {
          ++index;
          skipWhiteSpace();
          return '';
        }
        break;

      case 'x':
        if (features.hexEscapes) {
          // \xXX, where XX is a sequence of exactly two hexadecimal digits
          if (isHexDigit(input.charCodeAt(index + 1)) &&
              isHexDigit(input.charCodeAt(index + 2))) {
            index += 3;
            return String.fromCharCode(parseInt(input.slice(sequenceStart + 1, index), 16));
          }
          raise(null, errors.hexadecimalDigitExpected, '\\' + input.slice(sequenceStart, index + 2));
        }
        break;

      case 'u':
        if (features.unicodeEscapes)
          return readUnicodeEscapeSequence();
        break;

      case '\\': case '"': case "'":
        return input.charAt(index++);
    }

    if (features.strictEscapes)
      raise(null, errors.invalidEscape, '\\' + input.slice(sequenceStart, index + 1));
    return input.charAt(index++);
  }

  // Comments begin with -- after which it will be decided if they are
  // multiline comments or not.
  //
  // The multiline functionality works the exact same way as with string
  // literals so we reuse the functionality.

  function scanComment() {
    tokenStart = index;
    index += 2; // --

    var character = input.charAt(index)
      , content = ''
      , isLong = false
      , commentStart = index
      , lineStartComment = lineStart
      , lineComment = line;

    if ('[' === character) {
      content = readLongString(true);
      // This wasn't a multiline comment after all.
      if (false === content) content = character;
      else isLong = true;
    }
    // Scan until next line as long as it's not a multiline comment.
    if (!isLong) {
      while (index < length) {
        if (isLineTerminator(input.charCodeAt(index))) break;
        ++index;
      }
      if (options.comments) content = input.slice(commentStart, index);
    }

    if (options.comments) {
      var node = ast.comment(content, input.slice(tokenStart, index));

      // `Marker`s depend on tokens available in the parser and as comments are
      // intercepted in the lexer all location data is set manually.
      if (options.locations) {
        node.loc = {
            start: { line: lineComment, column: tokenStart - lineStartComment }
          , end: { line: line, column: index - lineStart }
        };
      }
      if (options.ranges) {
        node.range = [tokenStart, index];
      }
      if (options.onCreateNode) options.onCreateNode(node);
      comments.push(node);
    }
  }

  // Read a multiline string by calculating the depth of `=` characters and
  // then appending until an equal depth is found.

  function readLongString(isComment) {
    var level = 0
      , content = ''
      , terminator = false
      , character, stringStart, firstLine = line;

    ++index; // [

    // Calculate the depth of the comment.
    while ('=' === input.charAt(index + level)) ++level;
    // Exit, this is not a long string afterall.
    if ('[' !== input.charAt(index + level)) return false;

    index += level + 1;

    // If the first character is a newline, ignore it and begin on next line.
    if (isLineTerminator(input.charCodeAt(index))) consumeEOL();

    stringStart = index;
    while (index < length) {
      // To keep track of line numbers run the `consumeEOL()` which increments
      // its counter.
      while (isLineTerminator(input.charCodeAt(index))) consumeEOL();

      character = input.charAt(index++);

      // Once the delimiter is found, iterate through the depth count and see
      // if it matches.
      if (']' === character) {
        terminator = true;
        for (var i = 0; i < level; ++i) {
          if ('=' !== input.charAt(index + i)) terminator = false;
        }
        if (']' !== input.charAt(index + level)) terminator = false;
      }

      // We reached the end of the multiline string. Get out now.
      if (terminator) {
        content += input.slice(stringStart, index - 1);
        index += level + 1;
        return content;
      }
    }

    raise(null, isComment ?
                errors.unfinishedLongComment :
                errors.unfinishedLongString,
          firstLine, '<eof>');
  }

  // ## Lex functions and helpers.

  // Read the next token.
  //
  // This is actually done by setting the current token to the lookahead and
  // reading in the new lookahead token.

  function next() {
    previousToken = token;
    token = lookahead;
    lookahead = lex();
  }

  // Consume a token if its value matches. Once consumed or not, return the
  // success of the operation.

  function consume(value) {
    if (value === token.value) {
      next();
      return true;
    }
    return false;
  }

  // Expect the next token value to match. If not, throw an exception.

  function expect(value) {
    if (value === token.value) next();
    else raise(token, errors.expected, value, token.value);
  }

  // ### Validation functions

  function isWhiteSpace(charCode) {
    return 9 === charCode || 32 === charCode || 0xB === charCode || 0xC === charCode;
  }

  function isLineTerminator(charCode) {
    return 10 === charCode || 13 === charCode;
  }

  function isDecDigit(charCode) {
    return charCode >= 48 && charCode <= 57;
  }

  function isHexDigit(charCode) {
    return (charCode >= 48 && charCode <= 57) || (charCode >= 97 && charCode <= 102) || (charCode >= 65 && charCode <= 70);
  }

  // From [Lua 5.2](http://www.lua.org/manual/5.2/manual.html#8.1) onwards
  // identifiers cannot use 'locale-dependent' letters (i.e. dependent on the C locale).
  // On the other hand, LuaJIT allows arbitrary octets ≥ 128 in identifiers.

  function isIdentifierStart(charCode) {
    if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122) || 95 === charCode)
      return true;
    if (features.extendedIdentifiers && charCode >= 128)
      return true;
    return false;
  }

  function isIdentifierPart(charCode) {
    if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122) || 95 === charCode || (charCode >= 48 && charCode <= 57))
      return true;
    if (features.extendedIdentifiers && charCode >= 128)
      return true;
    return false;
  }

  // [3.1 Lexical Conventions](http://www.lua.org/manual/5.2/manual.html#3.1)
  //
  // `true`, `false` and `nil` will not be considered keywords, but literals.

  function isKeyword(id) {
    switch (id.length) {
      case 2:
        return 'do' === id || 'if' === id || 'in' === id || 'or' === id;
      case 3:
        return 'and' === id || 'end' === id || 'for' === id || 'not' === id;
      case 4:
        if ('else' === id || 'then' === id)
          return true;
        if (features.labels && !features.contextualGoto)
          return ('goto' === id);
        return false;
      case 5:
        return 'break' === id || 'local' === id || 'until' === id || 'while' === id;
      case 6:
        return 'elseif' === id || 'repeat' === id || 'return' === id;
      case 8:
        return 'function' === id;
    }
    return false;
  }

  function isUnary(token) {
    if (Punctuator === token.type) return '#-~'.indexOf(token.value) >= 0;
    if (Keyword === token.type) return 'not' === token.value;
    return false;
  }

  // Check if the token syntactically closes a block.

  function isBlockFollow(token) {
    if (EOF === token.type) return true;
    if (Keyword !== token.type) return false;
    switch (token.value) {
      case 'else': case 'elseif':
      case 'end': case 'until':
        return true;
      default:
        return false;
    }
  }

  // Scope
  // -----

  // Store each block scope as a an array of identifier names. Each scope is
  // stored in an FILO-array.
  var scopes
    // The current scope index
    , scopeDepth
    // A list of all global identifier nodes.
    , globals;

  // Create a new scope inheriting all declarations from the previous scope.
  function createScope() {
    var scope = Array.apply(null, scopes[scopeDepth++]);
    scopes.push(scope);
    if (options.onCreateScope) options.onCreateScope();
  }

  // Exit and remove the current scope.
  function destroyScope() {
    var scope = scopes.pop();
    --scopeDepth;
    if (options.onDestroyScope) options.onDestroyScope();
  }

  // Add identifier name to the current scope if it doesnt already exist.
  function scopeIdentifierName(name) {
    if (options.onLocalDeclaration) options.onLocalDeclaration(name);
    if (-1 !== indexOf(scopes[scopeDepth], name)) return;
    scopes[scopeDepth].push(name);
  }

  // Add identifier to the current scope
  function scopeIdentifier(node) {
    scopeIdentifierName(node.name);
    attachScope(node, true);
  }

  // Attach scope information to node. If the node is global, store it in the
  // globals array so we can return the information to the user.
  function attachScope(node, isLocal) {
    if (!isLocal && -1 === indexOfObject(globals, 'name', node.name))
      globals.push(node);

    node.isLocal = isLocal;
  }

  // Is the identifier name available in this scope.
  function scopeHasName(name) {
    return (-1 !== indexOf(scopes[scopeDepth], name));
  }

  // Location tracking
  // -----------------
  //
  // Locations are stored in FILO-array as a `Marker` object consisting of both
  // `loc` and `range` data. Once a `Marker` is popped off the list an end
  // location is added and the data is attached to a syntax node.

  var locations = []
    , trackLocations;

  function createLocationMarker() {
    return new Marker(token);
  }

  function Marker(token) {
    if (options.locations) {
      this.loc = {
          start: {
            line: token.line
          , column: token.range[0] - token.lineStart
        }
        , end: {
            line: 0
          , column: 0
        }
      };
    }
    if (options.ranges) this.range = [token.range[0], 0];
  }

  // Complete the location data stored in the `Marker` by adding the location
  // of the *previous token* as an end location.
  Marker.prototype.complete = function() {
    if (options.locations) {
      this.loc.end.line = previousToken.lastLine || previousToken.line;
      this.loc.end.column = previousToken.range[1] - (previousToken.lastLineStart || previousToken.lineStart);
    }
    if (options.ranges) {
      this.range[1] = previousToken.range[1];
    }
  };

  Marker.prototype.bless = function (node) {
    if (this.loc) {
      var loc = this.loc;
      node.loc = {
        start: {
          line: loc.start.line,
          column: loc.start.column
        },
        end: {
          line: loc.end.line,
          column: loc.end.column
        }
      };
    }
    if (this.range) {
      node.range = [
        this.range[0],
        this.range[1]
      ];
    }
  };

  // Create a new `Marker` and add it to the FILO-array.
  function markLocation() {
    if (trackLocations) locations.push(createLocationMarker());
  }

  // Push an arbitrary `Marker` object onto the FILO-array.
  function pushLocation(marker) {
    if (trackLocations) locations.push(marker);
  }

  // Control flow tracking
  // ---------------------
  // A context object that validates loop breaks and `goto`-based control flow.

  function FullFlowContext() {
    this.scopes = [];
    this.pendingGotos = [];
  }

  FullFlowContext.prototype.isInLoop = function () {
    var i = this.scopes.length;
    while (i --> 0) {
      if (this.scopes[i].isLoop)
        return true;
    }
    return false;
  };

  FullFlowContext.prototype.pushScope = function (isLoop) {
    var scope = {
      labels: {},
      locals: [],
      deferredGotos: [],
      isLoop: !!isLoop
    };
    this.scopes.push(scope);
  };

  FullFlowContext.prototype.popScope = function () {
    for (var i = 0; i < this.pendingGotos.length; ++i) {
      var theGoto = this.pendingGotos[i];
      if (theGoto.maxDepth >= this.scopes.length)
        if (--theGoto.maxDepth <= 0)
          raise(theGoto.token, errors.labelNotVisible, theGoto.target);
    }

    this.scopes.pop();
  };

  FullFlowContext.prototype.addGoto = function (target, token) {
    var localCounts = [];

    for (var i = 0; i < this.scopes.length; ++i) {
      var scope = this.scopes[i];
      localCounts.push(scope.locals.length);
      if (Object.prototype.hasOwnProperty.call(scope.labels, target))
        return;
    }

    this.pendingGotos.push({
      maxDepth: this.scopes.length,
      target: target,
      token: token,
      localCounts: localCounts
    });
  };

  FullFlowContext.prototype.addLabel = function (name, token) {
    var scope = this.currentScope();

    if (Object.prototype.hasOwnProperty.call(scope.labels, name)) {
      raise(token, errors.labelAlreadyDefined, name, scope.labels[name].line);
    } else {
      var newGotos = [];

      for (var i = 0; i < this.pendingGotos.length; ++i) {
        var theGoto = this.pendingGotos[i];

        if (theGoto.maxDepth >= this.scopes.length && theGoto.target === name) {
          if (theGoto.localCounts[this.scopes.length - 1] < scope.locals.length) {
            scope.deferredGotos.push(theGoto);
          }
          continue;
        }

        newGotos.push(theGoto);
      }

      this.pendingGotos = newGotos;
    }

    scope.labels[name] = {
      localCount: scope.locals.length,
      line: token.line
    };
  };

  FullFlowContext.prototype.addLocal = function (name, token) {
    this.currentScope().locals.push({
      name: name,
      token: token
    });
  };

  FullFlowContext.prototype.currentScope = function () {
    return this.scopes[this.scopes.length - 1];
  };

  FullFlowContext.prototype.raiseDeferredErrors = function () {
    var scope = this.currentScope();
    var bads = scope.deferredGotos;
    for (var i = 0; i < bads.length; ++i) {
      var theGoto = bads[i];
      raise(theGoto.token, errors.gotoJumpInLocalScope, theGoto.target, scope.locals[theGoto.localCounts[this.scopes.length - 1]].name);
    }
    // Would be dead code currently, but may be useful later
    // if (bads.length)
    //   scope.deferredGotos = [];
  };

  // Simplified context that only checks the validity of loop breaks.

  function LoopFlowContext() {
    this.level = 0;
    this.loopLevels = [];
  }

  LoopFlowContext.prototype.isInLoop = function () {
    return !!this.loopLevels.length;
  };

  LoopFlowContext.prototype.pushScope = function (isLoop) {
    ++this.level;
    if (isLoop)
      this.loopLevels.push(this.level);
  };

  LoopFlowContext.prototype.popScope = function () {
    var levels = this.loopLevels;
    var levlen = levels.length;
    if (levlen) {
      if (levels[levlen - 1] === this.level)
        levels.pop();
    }
    --this.level;
  };

  LoopFlowContext.prototype.addGoto =
  LoopFlowContext.prototype.addLabel =
  /* istanbul ignore next */
  function () { throw new Error('This should never happen'); };

  LoopFlowContext.prototype.addLocal =
  LoopFlowContext.prototype.raiseDeferredErrors =
  function () {};

  function makeFlowContext() {
    return features.labels ? new FullFlowContext() : new LoopFlowContext();
  }

  // Parse functions
  // ---------------

  // Chunk is the main program object. Syntactically it's the same as a block.
  //
  //     chunk ::= block

  function parseChunk() {
    next();
    markLocation();
    if (options.scope) createScope();
    var flowContext = makeFlowContext();
    flowContext.allowVararg = true;
    flowContext.pushScope();
    var body = parseBlock(flowContext);
    flowContext.popScope();
    if (options.scope) destroyScope();
    if (EOF !== token.type) unexpected(token);
    // If the body is empty no previousToken exists when finishNode runs.
    if (trackLocations && !body.length) previousToken = token;
    return finishNode(ast.chunk(body));
  }

  // A block contains a list of statements with an optional return statement
  // as its last statement.
  //
  //     block ::= {stat} [retstat]

  function parseBlock(flowContext) {
    var block = []
      , statement;

    while (!isBlockFollow(token)) {
      // Return has to be the last statement in a block.
      // Likewise 'break' in Lua older than 5.2
      if ('return' === token.value || (!features.relaxedBreak && 'break' === token.value)) {
        block.push(parseStatement(flowContext));
        break;
      }
      statement = parseStatement(flowContext);
      consume(';');
      // Statements are only added if they are returned, this allows us to
      // ignore some statements, such as EmptyStatement.
      if (statement) block.push(statement);
    }

    // Doesn't really need an ast node
    return block;
  }

  // There are two types of statements, simple and compound.
  //
  //     statement ::= break | goto | do | while | repeat | return
  //          | if | for | function | local | label | assignment
  //          | functioncall | ';'

  function parseStatement(flowContext) {
    markLocation();

    if (Punctuator === token.type) {
      if (consume('::')) return parseLabelStatement(flowContext);
    }

    // When a `;` is encounted, simply eat it without storing it.
    if (features.emptyStatement) {
      if (consume(';')) {
        if (trackLocations) locations.pop();
        return;
      }
    }

    flowContext.raiseDeferredErrors();

    if (Keyword === token.type) {
      switch (token.value) {
        case 'local':    next(); return parseLocalStatement(flowContext);
        case 'if':       next(); return parseIfStatement(flowContext);
        case 'return':   next(); return parseReturnStatement(flowContext);
        case 'function': next();
          var name = parseFunctionName();
          return parseFunctionDeclaration(name);
        case 'while':    next(); return parseWhileStatement(flowContext);
        case 'for':      next(); return parseForStatement(flowContext);
        case 'repeat':   next(); return parseRepeatStatement(flowContext);
        case 'break':    next();
          if (!flowContext.isInLoop())
            raise(token, errors.noLoopToBreak, token.value);
          return parseBreakStatement();
        case 'do':       next(); return parseDoStatement(flowContext);
        case 'goto':     next(); return parseGotoStatement(flowContext);
      }
    }

    if (features.contextualGoto &&
        token.type === Identifier && token.value === 'goto' &&
        lookahead.type === Identifier && lookahead.value !== 'goto') {
      next(); return parseGotoStatement(flowContext);
    }

    // Assignments memorizes the location and pushes it manually for wrapper nodes.
    if (trackLocations) locations.pop();

    return parseAssignmentOrCallStatement(flowContext);
  }

  // ## Statements

  //     label ::= '::' Name '::'

  function parseLabelStatement(flowContext) {
    var nameToken = token
      , label = parseIdentifier();

    if (options.scope) {
      scopeIdentifierName('::' + nameToken.value + '::');
      attachScope(label, true);
    }

    expect('::');

    flowContext.addLabel(nameToken.value, nameToken);
    return finishNode(ast.labelStatement(label));
  }

  //     break ::= 'break'

  function parseBreakStatement() {
    return finishNode(ast.breakStatement());
  }

  //     goto ::= 'goto' Name

  function parseGotoStatement(flowContext) {
    var name = token.value
      , gotoToken = previousToken
      , label = parseIdentifier();

    flowContext.addGoto(name, gotoToken);
    return finishNode(ast.gotoStatement(label));
  }

  //     do ::= 'do' block 'end'

  function parseDoStatement(flowContext) {
    if (options.scope) createScope();
    flowContext.pushScope();
    var body = parseBlock(flowContext);
    flowContext.popScope();
    if (options.scope) destroyScope();
    expect('end');
    return finishNode(ast.doStatement(body));
  }

  //     while ::= 'while' exp 'do' block 'end'

  function parseWhileStatement(flowContext) {
    var condition = parseExpectedExpression(flowContext);
    expect('do');
    if (options.scope) createScope();
    flowContext.pushScope(true);
    var body = parseBlock(flowContext);
    flowContext.popScope();
    if (options.scope) destroyScope();
    expect('end');
    return finishNode(ast.whileStatement(condition, body));
  }

  //     repeat ::= 'repeat' block 'until' exp

  function parseRepeatStatement(flowContext) {
    if (options.scope) createScope();
    flowContext.pushScope(true);
    var body = parseBlock(flowContext);
    expect('until');
    flowContext.raiseDeferredErrors();
    var condition = parseExpectedExpression(flowContext);
    flowContext.popScope();
    if (options.scope) destroyScope();
    return finishNode(ast.repeatStatement(condition, body));
  }

  //     retstat ::= 'return' [exp {',' exp}] [';']

  function parseReturnStatement(flowContext) {
    var expressions = [];

    if ('end' !== token.value) {
      var expression = parseExpression(flowContext);
      if (null != expression) expressions.push(expression);
      while (consume(',')) {
        expression = parseExpectedExpression(flowContext);
        expressions.push(expression);
      }
      consume(';'); // grammar tells us ; is optional here.
    }
    return finishNode(ast.returnStatement(expressions));
  }

  //     if ::= 'if' exp 'then' block {elif} ['else' block] 'end'
  //     elif ::= 'elseif' exp 'then' block

  function parseIfStatement(flowContext) {
    var clauses = []
      , condition
      , body
      , marker;

    // IfClauses begin at the same location as the parent IfStatement.
    // It ends at the start of `end`, `else`, or `elseif`.
    if (trackLocations) {
      marker = locations[locations.length - 1];
      locations.push(marker);
    }
    condition = parseExpectedExpression(flowContext);
    expect('then');
    if (options.scope) createScope();
    flowContext.pushScope();
    body = parseBlock(flowContext);
    flowContext.popScope();
    if (options.scope) destroyScope();
    clauses.push(finishNode(ast.ifClause(condition, body)));

    if (trackLocations) marker = createLocationMarker();
    while (consume('elseif')) {
      pushLocation(marker);
      condition = parseExpectedExpression(flowContext);
      expect('then');
      if (options.scope) createScope();
      flowContext.pushScope();
      body = parseBlock(flowContext);
      flowContext.popScope();
      if (options.scope) destroyScope();
      clauses.push(finishNode(ast.elseifClause(condition, body)));
      if (trackLocations) marker = createLocationMarker();
    }

    if (consume('else')) {
      // Include the `else` in the location of ElseClause.
      if (trackLocations) {
        marker = new Marker(previousToken);
        locations.push(marker);
      }
      if (options.scope) createScope();
      flowContext.pushScope();
      body = parseBlock(flowContext);
      flowContext.popScope();
      if (options.scope) destroyScope();
      clauses.push(finishNode(ast.elseClause(body)));
    }

    expect('end');
    return finishNode(ast.ifStatement(clauses));
  }

  // There are two types of for statements, generic and numeric.
  //
  //     for ::= Name '=' exp ',' exp [',' exp] 'do' block 'end'
  //     for ::= namelist 'in' explist 'do' block 'end'
  //     namelist ::= Name {',' Name}
  //     explist ::= exp {',' exp}

  function parseForStatement(flowContext) {
    var variable = parseIdentifier()
      , body;

    // The start-identifier is local.

    if (options.scope) {
      createScope();
      scopeIdentifier(variable);
    }

    // If the first expression is followed by a `=` punctuator, this is a
    // Numeric For Statement.
    if (consume('=')) {
      // Start expression
      var start = parseExpectedExpression(flowContext);
      expect(',');
      // End expression
      var end = parseExpectedExpression(flowContext);
      // Optional step expression
      var step = consume(',') ? parseExpectedExpression(flowContext) : null;

      expect('do');
      flowContext.pushScope(true);
      body = parseBlock(flowContext);
      flowContext.popScope();
      expect('end');
      if (options.scope) destroyScope();

      return finishNode(ast.forNumericStatement(variable, start, end, step, body));
    }
    // If not, it's a Generic For Statement
    else {
      // The namelist can contain one or more identifiers.
      var variables = [variable];
      while (consume(',')) {
        variable = parseIdentifier();
        // Each variable in the namelist is locally scoped.
        if (options.scope) scopeIdentifier(variable);
        variables.push(variable);
      }
      expect('in');
      var iterators = [];

      // One or more expressions in the explist.
      do {
        var expression = parseExpectedExpression(flowContext);
        iterators.push(expression);
      } while (consume(','));

      expect('do');
      flowContext.pushScope(true);
      body = parseBlock(flowContext);
      flowContext.popScope();
      expect('end');
      if (options.scope) destroyScope();

      return finishNode(ast.forGenericStatement(variables, iterators, body));
    }
  }

  // Local statements can either be variable assignments or function
  // definitions. If a function definition is found, it will be delegated to
  // `parseFunctionDeclaration()` with the isLocal flag.
  //
  // This AST structure might change into a local assignment with a function
  // child.
  //
  //     local ::= 'local' 'function' Name funcdecl
  //        | 'local' Name {',' Name} ['=' exp {',' exp}]

  function parseLocalStatement(flowContext) {
    var name
      , declToken = previousToken;

    if (Identifier === token.type) {
      var variables = []
        , init = [];

      do {
        name = parseIdentifier();

        variables.push(name);
        flowContext.addLocal(name.name, declToken);
      } while (consume(','));

      if (consume('=')) {
        do {
          var expression = parseExpectedExpression(flowContext);
          init.push(expression);
        } while (consume(','));
      }

      // Declarations doesn't exist before the statement has been evaluated.
      // Therefore assignments can't use their declarator. And the identifiers
      // shouldn't be added to the scope until the statement is complete.
      if (options.scope) {
        for (var i = 0, l = variables.length; i < l; ++i) {
          scopeIdentifier(variables[i]);
        }
      }

      return finishNode(ast.localStatement(variables, init));
    }
    if (consume('function')) {
      name = parseIdentifier();
      flowContext.addLocal(name.name, declToken);

      if (options.scope) {
        scopeIdentifier(name);
        createScope();
      }

      // MemberExpressions are not allowed in local function statements.
      return parseFunctionDeclaration(name, true);
    } else {
      raiseUnexpectedToken('<name>', token);
    }
  }

  //     assignment ::= varlist '=' explist
  //     var ::= Name | prefixexp '[' exp ']' | prefixexp '.' Name
  //     varlist ::= var {',' var}
  //     explist ::= exp {',' exp}
  //
  //     call ::= callexp
  //     callexp ::= prefixexp args | prefixexp ':' Name args

  function parseAssignmentOrCallStatement(flowContext) {
    // Keep a reference to the previous token for better error messages in case
    // of invalid statement
    var previous = token
      , marker, startMarker;
    var lvalue, base, name;

    var targets = [];

    if (trackLocations) startMarker = createLocationMarker();

    do {
      if (trackLocations) marker = createLocationMarker();

      if (Identifier === token.type) {
        name = token.value;
        base = parseIdentifier();
        // Set the parent scope.
        if (options.scope) attachScope(base, scopeHasName(name));
        lvalue = true;
      } else if ('(' === token.value) {
        next();
        base = parseExpectedExpression(flowContext);
        expect(')');
        lvalue = false;
      } else {
        return unexpected(token);
      }

      both: for (;;) {
        var newBase;

        switch (StringLiteral === token.type ? '"' : token.value) {
        case '.':
        case '[':
          lvalue = true;
          break;
        case ':':
        case '(':
        case '{':
        case '"':
          lvalue = null;
          break;
        default:
          break both;
        }

        base = parsePrefixExpressionPart(base, marker, flowContext);
      }

      targets.push(base);

      if (',' !== token.value)
        break;

      if (!lvalue) {
        return unexpected(token);
      }

      next();
    } while (true);

    if (targets.length === 1 && lvalue === null) {
      pushLocation(marker);
      return finishNode(ast.callStatement(targets[0]));
    } else if (!lvalue) {
      return unexpected(token);
    }

    expect('=');

    var values = [];

    do {
      values.push(parseExpectedExpression(flowContext));
    } while (consume(','));

    pushLocation(startMarker);
    return finishNode(ast.assignmentStatement(targets, values));
  }

  // ### Non-statements

  //     Identifier ::= Name

  function parseIdentifier() {
    markLocation();
    var identifier = token.value;
    if (Identifier !== token.type) raiseUnexpectedToken('<name>', token);
    next();
    return finishNode(ast.identifier(identifier));
  }

  function parseParameterList(flowContext, terminator) {
    var parameters = [];

    // The declaration has arguments
    if (!consume(terminator)) {
      // Arguments are a comma separated list of identifiers, optionally ending
      // with a vararg.
      while (true) {
        if (Identifier === token.type) {
          var parameter = parseIdentifier();
          // Function parameters are local.
          if (options.scope) scopeIdentifier(parameter);

          parameters.push(parameter);

          if (consume(',')) continue;
        }
        // No arguments are allowed after a vararg.
        else if (VarargLiteral === token.type) {
          flowContext.allowVararg = true;
          parameters.push(parsePrimaryExpression(flowContext));
        } else {
          raiseUnexpectedToken('<name> or \'...\'', token);
        }
        expect(terminator);
        break;
      }
    }

    return parameters;
  }

  // Parse the functions parameters and body block. The name should already
  // have been parsed and passed to this declaration function. By separating
  // this we allow for anonymous functions in expressions.
  //
  // For local functions there's a boolean parameter which needs to be set
  // when parsing the declaration.
  //
  //     funcdecl ::= '(' [parlist] ')' block 'end'
  //     parlist ::= Name {',' Name} | [',' '...'] | '...'

  function parseFunctionDeclaration(name, isLocal) {
    var flowContext = makeFlowContext();
    flowContext.pushScope();

    expect('(');

    var parameters = parseParameterList(flowContext,  ')');
    var body = parseBlock(flowContext);

    flowContext.popScope();
    expect('end');
    if (options.scope) destroyScope();

    isLocal = isLocal || false;
    return finishNode(ast.functionStatement(name, parameters, isLocal, body));
  }

  // Parse a MoonSharp short anonymous function. Unlike regular function
  // syntax which can appear as both a statement and an expression, short
  // anonymous functions are only allowed as an expression. Short anonymous
  // functions are made of a parameter list and a singular expression.
  //
  //     shortfuncdef ::= '|' [parlist] '|' expression
  //     parlist ::= Name {',' Name} | [',' '...'] | '...'

  function parseShortFunctionDefinition() {
    var flowContext = makeFlowContext();
    flowContext.pushScope();

    var parameters = parseParameterList(flowContext, '|');

    if (token.type === Punctuator && token.value === '|') { // Non-parenthesized nested short functions are forbidden.
      raiseUnexpectedToken('<expression>', token);
    }

    var expression = parseExpectedExpression(flowContext);

    flowContext.popScope();
    if (options.scope) destroyScope();

    return finishNode(ast.shortFunctionDefinition(parameters, expression));
  }

  // Parse the function name as identifiers and member expressions.
  //
  //     Name {'.' Name} [':' Name]

  function parseFunctionName() {
    var base, name, marker;

    if (trackLocations) marker = createLocationMarker();
    base = parseIdentifier();

    if (options.scope) {
      attachScope(base, scopeHasName(base.name));
      createScope();
    }

    while (consume('.')) {
      pushLocation(marker);
      name = parseIdentifier();
      base = finishNode(ast.memberExpression(base, '.', name));
    }

    if (consume(':')) {
      pushLocation(marker);
      name = parseIdentifier();
      base = finishNode(ast.memberExpression(base, ':', name));
      if (options.scope) scopeIdentifierName('self');
    }

    return base;
  }

  //     tableconstructor ::= '{' [fieldlist] '}'
  //     fieldlist ::= field {fieldsep field} fieldsep
  //     field ::= '[' exp ']' '=' exp | Name = 'exp' | exp
  //
  //     fieldsep ::= ',' | ';'

  function parseTableConstructor(flowContext) {
    var fields = []
      , key, value;

    while (true) {
      markLocation();
      if (Punctuator === token.type && consume('[')) {
        key = parseExpectedExpression(flowContext);
        expect(']');
        expect('=');
        value = parseExpectedExpression(flowContext);
        fields.push(finishNode(ast.tableKey(key, value)));
      } else if (Identifier === token.type) {
        if ('=' === lookahead.value) {
          key = parseIdentifier();
          next();
          value = parseExpectedExpression(flowContext);
          fields.push(finishNode(ast.tableKeyString(key, value)));
        } else {
          value = parseExpectedExpression(flowContext);
          fields.push(finishNode(ast.tableValue(value)));
        }
      } else {
        if (null == (value = parseExpression(flowContext))) {
          locations.pop();
          break;
        }
        fields.push(finishNode(ast.tableValue(value)));
      }
      if (',;'.indexOf(token.value) >= 0) {
        next();
        continue;
      }
      break;
    }
    expect('}');
    return finishNode(ast.tableConstructorExpression(fields));
  }

  // Expression parser
  // -----------------
  //
  // Expressions are evaluated and always return a value. If nothing is
  // matched null will be returned.
  //
  //     exp ::= (unop exp | primary | prefixexp ) { binop exp }
  //
  //     primary ::= nil | false | true | Number | String | '...'
  //          | functiondef | shortfunctiondef | tableconstructor
  //
  //     prefixexp ::= (Name | '(' exp ')' ) { '[' exp ']'
  //          | '.' Name | ':' Name args | args }
  //

  function parseExpression(flowContext) {
    var expression = parseSubExpression(0, flowContext);
    return expression;
  }

  // Parse an expression expecting it to be valid.

  function parseExpectedExpression(flowContext) {
    var expression = parseExpression(flowContext);
    if (null == expression) raiseUnexpectedToken('<expression>', token);
    else return expression;
  }


  // Return the precedence priority of the operator.
  //
  // As unary `-` can't be distinguished from binary `-`, unary precedence
  // isn't described in this table but in `parseSubExpression()` itself.
  //
  // As this function gets hit on every expression it's been optimized due to
  // the expensive CompareICStub which took ~8% of the parse time.

  function binaryPrecedence(operator) {
    var charCode = operator.charCodeAt(0)
      , length = operator.length;

    if (1 === length) {
      switch (charCode) {
        case 94: return 12; // ^
        case 42: case 47: case 37: return 10; // * / %
        case 43: case 45: return 9; // + -
        case 38: return 6; // &
        case 126: return 5; // ~
        case 124: return 4; // |
        case 60: case 62: return 3; // < >
      }
    } else if (2 === length) {
      switch (charCode) {
        case 47: return 10; // //
        case 46: return 8; // ..
        case 60: case 62:
            if('<<' === operator || '>>' === operator) return 7; // << >>
            return 3; // <= >=
        case 61: case 126: case 33: return 3; // == ~= !=
        case 111: return 1; // or
      }
    } else if (97 === charCode && 'and' === operator) return 2;
    return 0;
  }

  // Implement an operator-precedence parser to handle binary operator
  // precedence.
  //
  // We use this algorithm because it's compact, it's fast and Lua core uses
  // the same so we can be sure our expressions are parsed in the same manner
  // without excessive amounts of tests.
  //
  //     exp ::= (unop exp | primary | prefixexp ) { binop exp }

  function parseSubExpression(minPrecedence, flowContext) {
    var operator = token.value
    // The left-hand side in binary operations.
      , expression, marker;

    if (trackLocations) marker = createLocationMarker();

    // UnaryExpression
    if (isUnary(token)) {
      markLocation();
      next();
      var argument = parseSubExpression(10, flowContext);
      if (argument == null) raiseUnexpectedToken('<expression>', token);
      expression = finishNode(ast.unaryExpression(operator, argument));
    }
    if (null == expression) {
      // PrimaryExpression
      expression = parsePrimaryExpression(flowContext);

      // PrefixExpression
      if (null == expression) {
        expression = parsePrefixExpression(flowContext);
      }
    }
    // This is not a valid left hand expression.
    if (null == expression) return null;

    var precedence;
    while (true) {
      operator = token.value;

      precedence = (Punctuator === token.type || Keyword === token.type) ?
        binaryPrecedence(operator) : 0;

      if (precedence === 0 || precedence <= minPrecedence) break;
      // Right-hand precedence operators
      if ('^' === operator || '..' === operator) --precedence;
      next();
      var right = parseSubExpression(precedence, flowContext);
      if (null == right) raiseUnexpectedToken('<expression>', token);
      // Push in the marker created before the loop to wrap its entirety.
      if (trackLocations) locations.push(marker);
      expression = finishNode(ast.binaryExpression(operator, expression, right));

    }
    return expression;
  }

  //     prefixexp ::= prefix {suffix}
  //     prefix ::= Name | '(' exp ')'
  //     suffix ::= '[' exp ']' | '.' Name | ':' Name args | args
  //
  //     args ::= '(' [explist] ')' | tableconstructor | String

  function parsePrefixExpressionPart(base, marker, flowContext) {
    var expressions, identifier;

    if (Punctuator === token.type) {
      switch (token.value) {
        case '[':
          pushLocation(marker);
          next();
          expressions = [];
          expressions.push(parseExpectedExpression(flowContext));
          while (consume(',')) {
            expressions.push(parseExpectedExpression(flowContext));
          }
          expect(']');
          return expressions.length === 1 ? finishNode(ast.indexExpression(base, expressions[0]))
            : finishNode(ast.indexesExpression(base, expressions));
        case '.':
          pushLocation(marker);
          next();
          identifier = parseIdentifier();
          return finishNode(ast.memberExpression(base, '.', identifier));
        case ':':
          pushLocation(marker);
          next();
          identifier = parseIdentifier();
          base = finishNode(ast.memberExpression(base, ':', identifier));
          // Once a : is found, this has to be a CallExpression, otherwise
          // throw an error.
          pushLocation(marker);
          return parseCallExpression(base, flowContext);
        case '(': case '{': // args
          pushLocation(marker);
          return parseCallExpression(base, flowContext);
      }
    } else if (StringLiteral === token.type) {
      pushLocation(marker);
      return parseCallExpression(base, flowContext);
    }

    return null;
  }

  function parsePrefixExpression(flowContext) {
    var base, name, marker;

    if (trackLocations) marker = createLocationMarker();

    // The prefix
    if (Identifier === token.type) {
      name = token.value;
      base = parseIdentifier();
      // Set the parent scope.
      if (options.scope) attachScope(base, scopeHasName(name));
    } else if (consume('(')) {
      base = parseExpectedExpression(flowContext);
      expect(')');
    } else {
      return null;
    }

    // The suffix
    for (;;) {
      var newBase = parsePrefixExpressionPart(base, marker, flowContext);
      if (newBase === null)
        break;
      base = newBase;
    }

    return base;
  }

  //     args ::= '(' [explist] ')' | tableconstructor | String

  function parseCallExpression(base, flowContext) {
    if (Punctuator === token.type) {
      switch (token.value) {
        case '(':
          if (!features.emptyStatement) {
            if (token.line !== previousToken.line)
              raise(null, errors.ambiguousSyntax, token.value);
          }
          next();

          // List of expressions
          var expressions = [];
          var expression = parseExpression(flowContext);
          if (null != expression) expressions.push(expression);
          while (consume(',')) {
            expression = parseExpectedExpression(flowContext);
            expressions.push(expression);
          }

          expect(')');
          return finishNode(ast.callExpression(base, expressions));

        case '{':
          markLocation();
          next();
          var table = parseTableConstructor(flowContext);
          return finishNode(ast.tableCallExpression(base, table));
      }
    } else if (StringLiteral === token.type) {
      return finishNode(ast.stringCallExpression(base, parsePrimaryExpression(flowContext)));
    }

    raiseUnexpectedToken('function arguments', token);
  }

  //     primary ::= String | Numeric | nil | true | false
  //          | functiondef | shortfunctiondef | tableconstructor | '...'

  function parsePrimaryExpression(flowContext) {
    var literals = StringLiteral | NumericLiteral | BooleanLiteral | NilLiteral | VarargLiteral
      , value = token.value
      , type = token.type
      , marker;

    if (trackLocations) marker = createLocationMarker();

    if (type === VarargLiteral && !flowContext.allowVararg) {
      raise(token, errors.cannotUseVararg, token.value);
    }

    if (type & literals) {
      pushLocation(marker);
      var raw = input.slice(token.range[0], token.range[1]);
      next();
      return finishNode(ast.literal(type, value, raw));
    } else if ((Keyword === type && 'function' === value) || (Punctuator === type && '|' === value)) {
      pushLocation(marker);
      next();
      if (options.scope) createScope();
      return Punctuator === type ? parseShortFunctionDefinition() : parseFunctionDeclaration(null);
    } else if (consume('{')) {
      pushLocation(marker);
      return parseTableConstructor(flowContext);
    }
  }

  // Parser
  // ------

  // Export the main parser.
  //
  //   - `wait` Hold parsing until end() is called. Defaults to false
  //   - `comments` Store comments. Defaults to true.
  //   - `scope` Track identifier scope. Defaults to false.
  //   - `locations` Store location information. Defaults to false.
  //   - `ranges` Store the start and end character locations. Defaults to
  //     false.
  //   - `onCreateNode` Callback which will be invoked when a syntax node is
  //     created.
  //   - `onCreateScope` Callback which will be invoked when a new scope is
  //     created.
  //   - `onDestroyScope` Callback which will be invoked when the current scope
  //     is destroyed.
  //
  // Example:
  //
  //     var parser = require('luaparser');
  //     parser.parse('i = 0');

  exports.parse = parse;

  var versionFeatures = {
    '5.1': {
    },
    '5.2': {
      labels: true,
      emptyStatement: true,
      hexEscapes: true,
      skipWhitespaceEscape: true,
      strictEscapes: true,
      relaxedBreak: true
    },
    '5.3': {
      labels: true,
      emptyStatement: true,
      hexEscapes: true,
      skipWhitespaceEscape: true,
      strictEscapes: true,
      unicodeEscapes: true,
      bitwiseOperators: true,
      integerDivision: true,
      relaxedBreak: true
    },
    'LuaJIT': {
      // XXX: LuaJIT language features may depend on compilation options; may need to
      // rethink how to handle this. Specifically, there is a LUAJIT_ENABLE_LUA52COMPAT
      // that removes contextual goto. Maybe add 'LuaJIT-5.2compat' as well?
      labels: true,
      contextualGoto: true,
      hexEscapes: true,
      skipWhitespaceEscape: true,
      strictEscapes: true,
      unicodeEscapes: true
    }
  };

  function parse(_input, _options) {
    if ('undefined' === typeof _options && 'object' === typeof _input) {
      _options = _input;
      _input = undefined;
    }
    if (!_options) _options = {};

    input = _input || '';
    options = assign({}, defaultOptions, _options);

    // Rewind the lexer
    index = 0;
    line = 1;
    lineStart = 0;
    length = input.length;
    // When tracking identifier scope, initialize with an empty scope.
    scopes = [[]];
    scopeDepth = 0;
    globals = [];
    locations = [];

    if (!Object.prototype.hasOwnProperty.call(versionFeatures, options.luaVersion)) {
      throw new Error(sprintf("Lua version '%1' not supported", options.luaVersion));
    }

    features = assign({}, versionFeatures[options.luaVersion]);
    if (options.extendedIdentifiers !== void 0)
      features.extendedIdentifiers = !!options.extendedIdentifiers;

    if (options.comments) comments = [];
    if (!options.wait) return end();
    return exports;
  }

  // Write to the source code buffer without beginning the parse.
  exports.write = write;

  function write(_input) {
    input += String(_input);
    length = input.length;
    return exports;
  }

  // Send an EOF and begin parsing.
  exports.end = end;

  function end(_input) {
    if ('undefined' !== typeof _input) write(_input);

    // Ignore shebangs.
    if (input && input.substr(0, 2) === '#!') input = input.replace(/^.*/, function (line) {
      return line.replace(/./g, ' ');
    });

    length = input.length;
    trackLocations = options.locations || options.ranges;
    // Initialize with a lookahead token.
    lookahead = lex();

    var chunk = parseChunk();
    if (options.comments) chunk.comments = comments;
    if (options.scope) chunk.globals = globals;

    /* istanbul ignore if */
    if (locations.length > 0)
      throw new Error('Location tracking failed. This is most likely a bug in luaparse');

    return chunk;
  }

}));
/* vim: set sw=2 ts=2 et tw=79 : */


/***/ }),

/***/ 7858:
/***/ ((__unused_webpack_module, exports) => {

"use strict";


exports.fromCallback = function (fn) {
  return Object.defineProperty(function (...args) {
    if (typeof args[args.length - 1] === 'function') fn.apply(this, args)
    else {
      return new Promise((resolve, reject) => {
        fn.call(
          this,
          ...args,
          (err, res) => (err != null) ? reject(err) : resolve(res)
        )
      })
    }
  }, 'name', { value: fn.name })
}

exports.fromPromise = function (fn) {
  return Object.defineProperty(function (...args) {
    const cb = args[args.length - 1]
    if (typeof cb !== 'function') return fn.apply(this, args)
    else fn.apply(this, args.slice(0, -1)).then(r => cb(null, r), cb)
  }, 'name', { value: fn.name })
}


/***/ }),

/***/ 8891:
/***/ (function(__unused_webpack_module, exports, __nccwpck_require__) {

"use strict";

var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
const path_1 = __importDefault(__nccwpck_require__(1017));
const core_1 = __nccwpck_require__(3539);
const fs_extra_1 = __importDefault(__nccwpck_require__(6417));
const luabundle_1 = __importDefault(__nccwpck_require__(1054));
const luamin_1 = __importDefault(__nccwpck_require__(4825));
const IS_DEV_ENVIRONMENT = process.env.NODE_ENV === 'development';
const sourcePath = IS_DEV_ENVIRONMENT
    ? path_1.default.join('..', '..', '..', 'src')
    : path_1.default.join(...(0, core_1.getInput)('source', { required: true }).split('/'));
const outputPath = IS_DEV_ENVIRONMENT
    ? path_1.default.join('..', '..', '..', 'dist')
    : path_1.default.join(...(0, core_1.getInput)('output', { required: true }).split('/'));
/*
   remove old bundled files (if they exist)
    */
fs_extra_1.default.ensureDirSync(outputPath);
fs_extra_1.default.readdirSync(outputPath).forEach(fileName => fs_extra_1.default.removeSync(fileName));
/*
   bundle and save source files
    */
const sourceFiles = fs_extra_1.default.readdirSync(sourcePath).filter(fileName => fileName.endsWith('.lua'));
const mixins = fs_extra_1.default.readdirSync(path_1.default.join(sourcePath, 'mixin')).filter(fileName => fileName.endsWith('.lua'));
sourceFiles.forEach(file => {
    if (file.startsWith('personal'))
        return;
    const source = fs_extra_1.default.readFileSync(path_1.default.join(sourcePath, file), 'utf8');
    let expressionHandlerOutput = source.includes('library.mixin') ? mixins : [];
    const bundledFile = luabundle_1.default.bundle(path_1.default.join(sourcePath, file), {
        paths: ['?', '?.lua', path_1.default.resolve(path_1.default.join(sourcePath, 'library', 'general_library.lua'))],
        expressionHandler: (_, __) => expressionHandlerOutput,
    });
    fs_extra_1.default.writeFileSync(path_1.default.join(outputPath, file), luamin_1.default.minify(bundledFile));
});


/***/ }),

/***/ 9491:
/***/ ((module) => {

"use strict";
module.exports = require("assert");

/***/ }),

/***/ 2057:
/***/ ((module) => {

"use strict";
module.exports = require("constants");

/***/ }),

/***/ 7147:
/***/ ((module) => {

"use strict";
module.exports = require("fs");

/***/ }),

/***/ 2037:
/***/ ((module) => {

"use strict";
module.exports = require("os");

/***/ }),

/***/ 1017:
/***/ ((module) => {

"use strict";
module.exports = require("path");

/***/ }),

/***/ 2781:
/***/ ((module) => {

"use strict";
module.exports = require("stream");

/***/ }),

/***/ 3837:
/***/ ((module) => {

"use strict";
module.exports = require("util");

/***/ }),

/***/ 4131:
/***/ ((module) => {

"use strict";
module.exports = JSON.parse('{"name":"luabundle","description":"Bundles several Lua files into a single file.","version":"1.6.0","author":"Benjamin Dobell @Benjamin-Dobell","bugs":"https://github.com/Benjamin-Dobell/luabundle/issues","dependencies":{"moonsharp-luaparse":"^0.2.4","tslib":"^1"},"devDependencies":{"@types/node":"^13.7.2","eslint":"^6.8.0","fs-extra":"^8.1.0","klaw-sync":"^6.0.0","rimraf":"^3.0.2","typescript":"^3.7.5"},"engines":{"node":">=8.0.0"},"homepage":"https://github.com/Benjamin-Dobell/luabundle","keywords":["lua","require","modules","bundler","bundling"],"license":"MIT","main":"index.js","repository":"Benjamin-Dobell/luabundle","scripts":{"build":"node scripts/build.js","prepack":"node scripts/prepack.js","posttest":"eslint . --config .eslintrc","test":"echo NO TESTS"},"types":"index.d.ts"}');

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __nccwpck_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			id: moduleId,
/******/ 			loaded: false,
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		var threw = true;
/******/ 		try {
/******/ 			__webpack_modules__[moduleId].call(module.exports, module, module.exports, __nccwpck_require__);
/******/ 			threw = false;
/******/ 		} finally {
/******/ 			if(threw) delete __webpack_module_cache__[moduleId];
/******/ 		}
/******/ 	
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/node module decorator */
/******/ 	(() => {
/******/ 		__nccwpck_require__.nmd = (module) => {
/******/ 			module.paths = [];
/******/ 			if (!module.children) module.children = [];
/******/ 			return module;
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/compat */
/******/ 	
/******/ 	if (typeof __nccwpck_require__ !== 'undefined') __nccwpck_require__.ab = __dirname + "/";
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module is referenced by other modules so it can't be inlined
/******/ 	var __webpack_exports__ = __nccwpck_require__(8891);
/******/ 	module.exports = __webpack_exports__;
/******/ 	
/******/ })()
;