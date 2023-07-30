
contract EllipticCurve {
    struct Point {
        uint x;
        uint y;
    }
    uint private constant p = 0x0ded3dc4be6d0d1d91a46b371d;
    uint private constant a = 0x00000000000000000000000000;
    uint private constant b = 0x00000000000000000000000001;
    uint private constant n = 0xd0d3dc4be6d0d1d91a46b371e;
    Point private generator = Point(0x0b8f7b7b963b86f8a27ab0b288, 0x061bab2e6f5d749cbb10189162);

    function pointMultiply(Point memory point, uint scalar) public pure returns(Point memory) {
        require(isOnCurve(point), "point is not on the curve");
    
    Point memory result = Point(p, p); //consider point at infinity
    Point memory current = point;
    while (scalar != 0) {
        if (scalar & 1 == 1) {
            result = pointAddition(result, current);
        }
            current = pointAddition(current, current);
            scalar = scalar >> 1;
        }
         return result;
    }
   


    function verifySignature(bytes32 message, uint r, uint s, Point memory publicKey) public view returns(bool) {
       

            require(isOnCurve(publicKey), "Public key is not on the curve");
            require(r != 0 && s != 0 && r < n && s < n / 2 + 1, "Wrong signature");

            uint w = modInverse(s, n);
            uint ul = mulmod(uint(sha256(abi.encodePacked(message))), w, n);
            uint u2 = mulmod(r, w, n);

            Point memory result = pointAddition(pointMultiply(generator, ul), pointMultiply(publicKey, u2));
                        return (result.x == r % n);

    }                    

    function isOnCurve(Point memory pt) public pure returns(bool) {
        if (pt.x >= p || pt.y >= p) {
            return false;
        }
        uint lhs = mulmod(pt.y, pt.y, p); 
        uint rhs = addmod(addmod(mulmod(pt.x, mulmod(pt.x, pt.x, p), p), mulmod(a, pt.x, p), p), b, p);
        return lhs == rhs;
    }


    function pointAddition(Point memory p1, Point memory p2) private pure returns(Point memory) {
        if (p1.x == p && p1.y == p) {
            return p2;
        }
        if (p2.x == p && p2.y == p) {
            return p1;
        }
        uint m;


        if (p1.x == p2.x) {
            if (p1.y == p2.y) {
                 m = mulmod(addmod(mulmod(3, mulmod(p1.x, p1.x, p), p), a, p), modInverse(mulmod(2,p1.y, p), p), p);
            } else {
                 return Point(p, p); // point at infinity
            }
            } else {
                m = mulmod(modDiff(p1.y, p2.y, p), modInverse(modDiff(p1.x, p2.x, p), p), p); 
    }

        uint x3 = modDiff(mulmod(m, m, p), addmod(p1.x, p2.x, p), p) % p;
        uint y3 = modDiff(mulmod(m, modDiff(p1.x, x3, p), p), p1.y, p) % p;

        
    return Point(x3, y3);
}

        function modInverse(uint aa, uint m) private pure returns(uint) {
            uint256 q = 0;
            uint256 newT = 1;
            uint256 r= m;
            uint256 t;
            while (aa != 0) {
                t = r / aa;
                (q, newT)=(newT, addmod(q, (m-mulmod(t, newT, m)), m));
                (r, aa)=(aa, r-aa * t);
            }
            return q;
        }

        function modDiff(uint x, uint y, uint mod) private pure returns(uint) {
            return x > y ? (x-y) : (mod - (y - x));
        }
}