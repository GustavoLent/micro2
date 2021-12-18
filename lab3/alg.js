function slli(bin, amount) {
    return bin << amount
}

function srli(bin, amount) {
    return bin >>> amount
}

function allZero(bin) {
    return bin == 0x0
}

function _max(v1, v2) {
    let r2 = 0

    if (v1 > v2) {
        r2 = v1

    }
    else {
        r2 = v2
    }

    return r2
}

let value = 0x3EFD6 // 111110111111010110
// let value = 0x3F // 111111
// let value = 0xDD // 11011101
// let value = 0x2 // 10
let mask = 0x1   // primeiro bit menos significativo

let counter = 0
let greater = 0

do {

    let curr = value & mask

    if (curr == 1) {
        counter++
    } else {
        greater = _max(counter, greater)
        counter = 0
    }

    value = srli(value, 1)

} while (!allZero(value))

greater = _max(counter, greater)

console.log(greater)
