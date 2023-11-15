pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../Gaussian.sol";
import "./HelperInvariant.sol";

contract DifferentialTests is Test {
    enum DifferentialFunctions {
        erfc,
        ierfc,
        cdf,
        ppf,
        invariant
    }

    string internal constant DATA_DIR = "test/differential/data/";
    uint256 internal constant EPSILON = 1e3;

    uint256 _epsilon;
    int256[129] _inputs;
    int256[129] _outputs;
    uint256[5][129] _invariantInputs;

    function setUp() public {
        generate();
    }

    function generate() public {
        // Run the reference implementation in javascript
        string[] memory runJsInputs = new string[](6);
        runJsInputs[0] = "npm";
        runJsInputs[1] = "--prefix";
        runJsInputs[2] = "test/differential/scripts/";
        runJsInputs[3] = "--silent";
        runJsInputs[4] = "run";
        runJsInputs[5] = "generate"; // Generates length 129 by default
        vm.ffi(runJsInputs);
    }

    function load(string memory key)
        public
        returns (int256[129] memory inputs, int256[129] memory outputs)
    {
        string[] memory cmds = new string[](2);
        // Get inputs.
        cmds[0] = "cat";
        cmds[1] = string(abi.encodePacked(DATA_DIR, key, "/input"));
        bytes memory result = vm.ffi(cmds);
        if (keccak256(abi.encodePacked(key)) == keccak256("invariant")) {
            _invariantInputs = abi.decode(result, (uint256[5][129]));
        } else {
            inputs = abi.decode(result, (int256[129]));
        }
        _inputs = inputs;
        // Get outputs.
        cmds[0] = "cat";
        cmds[1] = string(abi.encodePacked(DATA_DIR, key, "/output"));
        result = vm.ffi(cmds);
        outputs = abi.decode(result, (int256[129]));
        _outputs = outputs;
    }

    function testDifferentialERFC() public {
        _epsilon = EPSILON;
        load("erfc");
        run(DifferentialFunctions.erfc);
    }

    function testDifferentialIERFC() public {
        _epsilon = EPSILON;
        load("ierfc");
        run(DifferentialFunctions.ierfc);
    }

    function testDifferentialCDF() public {
        _epsilon = EPSILON;
        load("cdf");
        run(DifferentialFunctions.cdf);
    }

    function testDifferentialPPF() public {
        _epsilon = EPSILON * 10;
        load("ppf");
        run(DifferentialFunctions.ppf);
    }

    function testDifferentialInvariant() public {
        _epsilon = 1e9; // todo: fix/investigate
        load("invariant");
        run(DifferentialFunctions.invariant);
    }

    function run(DifferentialFunctions fn) public {
        if (fn == DifferentialFunctions.erfc) {
            _run(Gaussian.erfc);
        } else if (fn == DifferentialFunctions.ierfc) {
            _run(Gaussian.ierfc);
        } else if (fn == DifferentialFunctions.cdf) {
            _run(Gaussian.cdf);
        } else if (fn == DifferentialFunctions.ppf) {
            _run(Gaussian.ppf);
        } else if (fn == DifferentialFunctions.invariant) {
            _run(customInvariant);
        } else {
            revert();
        }
    }

    function customInvariant(uint256[5] memory args)
        internal
        pure
        returns (int256 k)
    {
        HelperInvariant.Args memory invariantInputs;
        uint256 y = args[0];
        invariantInputs.x = args[1];
        invariantInputs.K = args[2];
        invariantInputs.o = args[3];
        invariantInputs.t = args[4];
        k = HelperInvariant.invariant(invariantInputs, y);
    }

    function _run(function(int256) view returns (int256) method) internal {
        uint256 length = _inputs.length;
        for (uint256 i = 0; i < length; ++i) {
            int256 input = _inputs[i];
            int256 output = _outputs[i];
            int256 computed = method(input);
            assertApproxEqAbs(
                computed,
                output,
                _epsilon,
                vm.toString(input)
            );
        }
    }

    function _run(function(uint256[5] memory) view returns (int256) method)
        internal
    {
        uint256 length = _invariantInputs.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256[5] memory input = _invariantInputs[i];
            int256 output = _outputs[i];
            int256 computed = method(input);
            assertApproxEqAbs(
                computed,
                output,
                _epsilon,
                "computed-output-mismatch"
            );
        }
    }
}
