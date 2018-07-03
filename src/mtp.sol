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

        emit Log('buy', buyAmount);

        return buyAmount;
    }

    function joinLock(bytes32 cup, uint256 gemAmount)
        public note returns (uint256 skrAmount)
    {
        // per - gem per skr
        // gap - gap between buy and sell
        skrAmount = rdiv(gemAmount, wmul(tub.per(), tub.gap()));

        tub.join(skrAmount);
        tub.lock(cup, skrAmount);

        emit Log('lock', skrAmount);

        return skrAmount;
    }

    function draw(bytes32 cup, uint skrAmount, uint maxSai2Draw)
        public note returns (uint)
    {
        if(maxSai2Draw == 0) {
            return 0;
        }

        // mat - liquidation ratio
        // pip - ref per gem
        // par - ref per sai (target price)

        // Thanks Gonzalo!
        uint sai2Draw = min(
            rdiv(
                rmul(
                    rdiv(skrAmount * 10 ** 9, tub.mat()),
                    uint(tub.pip().read())
                ),
                tub.vox().par()
            ),
            maxSai2Draw
        );

        emit Log('draw', sai2Draw);

        tub.draw(cup, sai2Draw);

        return sai2Draw;
    }

    function marginTrade(uint sai, uint leverage)
        public payable note returns (bytes32 cup)
    {
        require(leverage >= 1 ether);

        tub.sai().transferFrom(msg.sender, this, sai);

        uint saiAtHand = sai;
        uint targetSaiSpent = wmul(saiAtHand, leverage);

        uint currentSaiSpent = 0;

        uint i = 0;

        cup = tub.open();

        do {
            uint gemAtHand = buy(saiAtHand);
            currentSaiSpent = currentSaiSpent + saiAtHand;
            uint skrLocked = joinLock(cup, gemAtHand);
            saiAtHand = draw(cup, skrLocked, targetSaiSpent - currentSaiSpent);

        } while (saiAtHand > 0 && i++ < 10); //TODO: requires discussion!

        // TODO: requires discussion!
        require(saiAtHand == 0);

        tub.give(cup, msg.sender);
    }


    function getOffers(OtcInterface otc, address payToken, address buyToken, uint start)
        public view returns (uint[100] ids, uint[100] payAmts, uint[100] buyAmts, address[100] owners, uint[100] timestamps)
    {
        uint i = 0;
        uint j = 0;

        uint offerId = otc.getBestOffer(payToken, buyToken);

        while(offerId != 0 && j < 100) {
            if(i++ >= start) {
                ids[j] = offerId;
                (payAmts[j],, buyAmts[j],, owners[j], timestamps[j]) = otc.offers(offerId);
                j++;
            }
            offerId = otc.getWorseOffer(offerId);
        }
    }

    function getOffers2(OtcInterface otc, uint offerId)
        public view returns (uint[100] ids, uint[100] payAmts, uint[100] buyAmts, address[100] owners, uint[100] timestamps)
    {
        uint i = 0;
        do {
            offerId = otc.getWorseOffer(offerId);
            if(offerId == 0) break;
            ids[i] = offerId;
            (payAmts[i],, buyAmts[i],, owners[i], timestamps[i]) = otc.offers(offerId);
        } while (i++ < 100);
    }
}