pragma solidity ^0.4.23;

import "ds-math/math.sol";
import "ds-note/note.sol";

import "./declarations.sol";

contract Mtp is DSMath, DSNote {

    OtcInterface otc;
    TubInterface tub;

    event Log(bytes32 param, uint x);

    constructor(OtcInterface otc_, TubInterface tub_) {
        otc = otc_;
        tub = tub_;

        tub.sai().approve(otc, uint(-1));
        tub.gem().approve(tub, uint(-1));
        tub.skr().approve(tub, uint(-1));
    }

    function buy(uint payAmount)
        public note returns (uint buyAmount)
    {
        buyAmount = otc.getBuyAmount(tub.gem(), tub.sai(), payAmount);
        otc.buyAllAmount(tub.gem(), buyAmount, tub.sai(), payAmount);

        return buyAmount;
    }

    function joinLock(bytes32 cup, uint256 wethAmount)
        public note returns (uint256 pethAmount)
    {
        pethAmount = rdiv(wethAmount, wmul(tub.per(), tub.gap()));

        tub.gem().balanceOf(this);

        tub.join(pethAmount);

        tub.lock(cup, pethAmount);

        return pethAmount;
    }

    function draw(bytes32 cup, uint wethAmount, uint maxSai2Draw)
        public note returns (uint)
    {
        Log('maxSai2Draw', maxSai2Draw);

        if(maxSai2Draw == 0) {
            return 0;
        }

        // Thanks Gonzalo!
        uint256 sai2Draw = min(
            rdiv(
                rmul(
                    rdiv(wethAmount * 10 ** 9, tub.mat()),
                    uint(tub.pip().read())
                ),
                tub.vox().par()
            ),
            maxSai2Draw
        );

        tub.draw(cup, sai2Draw);

        return sai2Draw;
    }

    function marginTrade(uint cash, uint leverage)
        public payable note returns (bytes32 cup)
    {

        require(leverage >= 1 ether && leverage < 3 ether);

        tub.sai().transferFrom(msg.sender, this, cash);

        Log('cash', cash);
        Log('leverage', leverage);

        uint cashAtHand = cash;
        uint targetCashSpent = wmul(cashAtHand, leverage);

        Log('targetCashSpent', targetCashSpent);

        uint currentCashSpent = 0;
        uint currentCollateralLocked = 0;

        uint i = 0;

        cup = tub.open();

        do {
            uint collateralAtHand = buy(cashAtHand);
            currentCashSpent = currentCashSpent + cashAtHand;

            uint collateralLocked = joinLock(cup, collateralAtHand);

            currentCollateralLocked = currentCollateralLocked + collateralLocked;

            Log('collateralLocked', collateralLocked);
            Log('targetCashSpent', targetCashSpent);
            Log('currentCashSpent', currentCashSpent);

            cashAtHand = draw(cup, collateralLocked, targetCashSpent - currentCashSpent);

            Log('cashAtHand', cashAtHand);

        } while (cashAtHand > 0 && i++ < 10); //TODO: requires discussion!

        // TODO: requires discussion!
        require(cashAtHand  == 0);

        Log('cup.ink', tub.ink(cup));

        tub.give(cup, msg.sender);
    }
}