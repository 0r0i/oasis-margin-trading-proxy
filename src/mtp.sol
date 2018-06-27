pragma solidity ^0.4.23;

import "ds-token/token.sol";
import "ds-math/math.sol";

import "./declarations.sol";

contract Mtp {

    OtcInterface otc;
    TubInterface tub;

    function Mtp(OtcInterface otc_, TubInterface tub_) {
        otc = otc_;
        tub = tub_;
    }

    function buy(uint payAmount)
        internal returns (uint buyAmount)
    {
        buyAmount = otc.getBuyAmount(tub.gem(), tub.sai(), payAmount);
        otc.buyAllAmount(tub.gem(), buyAmount, tub.sai(), payAmount);

        return buyAmount;
    }

    function joinLock(bytes32 cup, uint256 wethAmount)
        internal returns (uint256 pethAmount)
    {
        pethAmount = rdiv(ethAmount, wmul(tub.per(), tub.gap()));

        tub.join(pethAmount);
        tub.lock(cup, pethAmount);

        return pethAmount;
    }

    function draw(bytes32 cup, uint256 wethAmount, uint256 maxSai2Draw)
        internal returns (uint256)
    {
        if(maxSai2Draw == 0) {
            return 0;
        }

        // Thanks Gonzalo!
        uint256 sai2Draw = min(
            rdiv(
                rmul(
                    rdiv(ethAmount * 10 ** 9, tub.mat()),
                    uint(tub.pip().read())
                ),
                tub.vox().par()
            ),
            maxSai2Draw
        );

        tub.draw(cup, sai2Draw);

        return sai2Draw;
    }

    function marginTrade(uint leverage)
        public payable returns (bytes32 cup)
    {
        uint cashAtHand = msg.value;
        uint targetCashSpent = wmul(cashAtHand, leverage);

        uint currentCashSpent = 0;
        uint currentCollateralLocked = 0;

        uint i = 0;

        cup = tub.open();

        do {
            uint collateralAtHand = buy(cashAtHand);
            currentCashSpent = currentCashSpent + cashAtHand;

            collateralLocked = joinLock(collateralAtHand);
            currentCollateralLocked = currentCollateralLocked + collateralLocked;

            cashAtHand = draw(cup, collateralLocked, targetCashSpent - currentCashSpent);

        } while (cashAtHand > 0 && i++ < 10); //TODO: requires discussion!

        // TODO: requires discussion!
        require(cashAtHand  == 0);

        tub.give(cup, msg.sender);
    }
}