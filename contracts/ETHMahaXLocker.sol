// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {INFTLocker} from "./interfaces/INFTLocker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {IMetadataManager} from "./interfaces/IMetadataManager.sol";
import {VersionedInitializable} from "./proxy/VersionedInitializable.sol";

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract ETHMahaXLocker is VersionedInitializable {
    INFTLocker public locker;
    ISwapRouter public router;
    IERC20 public maha;
    IWETH9 public weth9;
    IMetadataManager public metadataManager;

    address private me;

    function initialize(
        address _locker,
        address _maha,
        address _weth,
        address _router,
        address _metadataManager
    ) external initializer {
        locker = INFTLocker(_locker);
        maha = IERC20(_maha);
        weth9 = IWETH9(_weth);

        maha.approve(_locker, type(uint256).max);
        maha.approve(_router, type(uint256).max);
        weth9.approve(_router, type(uint256).max);

        router = ISwapRouter(_router);
        metadataManager = IMetadataManager(_metadataManager);

        me = address(this);
    }

    receive() external payable {
        // do nothing
    }

    function getRevision() public pure virtual override returns (uint256) {
        return 0;
    }

    // convert maha into NFTs
    function createLocks(uint256 count, uint256 amount) public {
        // take maha from the user
        maha.transferFrom(msg.sender, me, amount * count);

        // create the locks for the user as specified.
        for (uint i = 0; i < count; i++) {
            locker.createLockFor(
                amount,
                86400 * 365 * 4, // 4 years
                msg.sender,
                false
            );
        }
    }

    // convert maha into NFTs
    function createLockWithMetadata(
        uint256 amount,
        IMetadataManager.TraitData memory data
    ) public {
        // take maha from the user
        maha.transferFrom(msg.sender, me, amount);

        // create the locks for the user as specified.
        uint256 id = locker.createLockFor(
            amount,
            86400 * 365 * 4, // 4 years
            msg.sender,
            false
        );

        // set metadata in the lock
        metadataManager.setTrait(id, data);
    }

    // convert the eth from sales into maha from uniswap
    function swapETHforMAHA(
        uint256 amountOutMAHA,
        uint256 amountInETHMax,
        address to,
        bool unwrapWETH
    ) public payable returns (uint256 amountIn) {
        if (unwrapWETH) weth9.deposit{value: amountInETHMax}();
        else weth9.transferFrom(msg.sender, me, amountInETHMax);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(weth9),
                tokenOut: address(maha),
                fee: 10000,
                recipient: to,
                deadline: block.timestamp,
                amountOut: amountOutMAHA,
                amountInMaximum: amountInETHMax,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = router.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInETHMax) {
            if (unwrapWETH) {
                weth9.withdraw(amountInETHMax - amountIn);
                payable(msg.sender).transfer(amountInETHMax - amountIn);
            } else weth9.transfer(msg.sender, amountInETHMax - amountIn);
        }
    }

    function swapETHforLocks(
        uint256 ethInMax,
        uint256 count,
        uint256 amount,
        bool unwrapWETH
    ) public payable {
        // weth -> maha
        swapETHforMAHA(count * amount, ethInMax, me, unwrapWETH);

        // create the locks for the user as specified.
        for (uint i = 0; i < count; i++) {
            locker.createLockFor(
                amount,
                86400 * 365 * 4, // 4 years
                msg.sender,
                false
            );
        }
    }

    function createLockWithMetadataWithETH(
        uint256 ethInMax,
        uint256 amount,
        bool unwrapWETH,
        IMetadataManager.TraitData memory data
    ) public payable {
        // weth -> maha
        swapETHforMAHA(amount, ethInMax, me, unwrapWETH);

        // create the locks for the user as specified.
        uint256 id = locker.createLockFor(
            amount,
            86400 * 365 * 4, // 4 years
            msg.sender,
            false
        );

        // set metadata
        metadataManager.setTrait(id, data);
    }

    function increaseAndEvolve(uint256 id, uint256 amount) public {
        // take maha
        maha.transferFrom(msg.sender, address(this), amount);

        // increase lock and evolve
        locker.increaseAmount(id, amount);
        metadataManager.evolveFor(id);
    }

    function increaseAndEvolveWithETH(
        uint256 id,
        uint256 ethInMax,
        uint256 amount,
        bool unwrapWETH
    ) public payable {
        // weth -> maha
        swapETHforMAHA(amount, ethInMax, me, unwrapWETH);

        // increase lock and evolve
        locker.increaseAmount(id, amount);
        metadataManager.evolveFor(id);
    }
}
