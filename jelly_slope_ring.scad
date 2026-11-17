// 昆虫ゼリー用 スロープ
// 穴にゼリーカップを置き、周囲の斜面から昆虫が登る
// corner = true: ケースのカドに置く形。カップを囲むリングから、カドと反対向きに斜面が広がる
// corner = false: 全周が斜面のドーナツ型

/* [ゼリーカップ] */
cup_diameter = 38;   // カップ直径 (mm)
cup_height   = 12;   // カップ高さ (mm)
clearance    = 0.6;  // 穴の遊び (直径に加算, mm)

/* [スロープ] */
slope_angle = 30;    // 斜面の角度 (度) 小さいほど緩やかで大きくなる
top_width   = 5;     // 穴のふちの平らな部分の幅 (mm)

/* [カド置き] */
corner        = true; // true: ケースのカドに置く形 / false: 全周スロープ
slope_span    = 90;   // 斜面の扇形の広がり (度) カドの対角方向を中心に広がる
edge_radius   = 4;    // 斜面の先端の角丸の半径 (mm)
corner_wall   = 9;    // カド側の、穴からケース壁までの厚み (mm) floor_radius より大きくする
corner_radius = 8;    // 壁と壁のカドの丸み (mm) ケースの R 以上にする（大きい分には収まる）
floor_radius  = 8;    // 床と壁の境目の丸み (mm) ケースの R 以上にする

/* [つまみ] */
grip           = true; // 斜面の中央（カドの対角方向）に、つまんで設置するための板を付ける
grip_gap       = 6;    // 穴のふちからつまみまでの間隔 (mm)
grip_length    = 14;   // つまみの長さ (mm)
grip_extra     = 8;    // リングの上面より上に出るアーチの高さ (mm)
grip_thickness = 3;    // 板の厚み (mm)

$fn = 180;
eps = 0.01;

r_in  = (cup_diameter + clearance) / 2;
h     = cup_height;
run   = h / tan(slope_angle);
r_top = r_in + top_width;
r_out = r_top + run;

// 斜面の断面（中心から外へ: 平らな上面 → 斜面）
module slope_profile() {
    polygon([[0, 0], [r_out, 0], [r_top, h], [0, h]]);
}

// ケースのカドの内側の形: 壁 (x = -d, y = -d)、壁どうしのカドに R、床と壁の境目にも R
d    = r_in + corner_wall;
rc   = min(corner_radius, d);
rf   = floor_radius;
size = 2 * (r_out + d);

// 高さ z で、壁から inset だけ内側に入った断面
module case_slice(z, inset) {
    r = max(rc - inset, 0.01);
    translate([-d + inset + r, -d + inset + r, z])
        linear_extrude(0.01) offset(r = r) square(size - 2 * r);
}

module corner_region() {
    n = 24;
    if (rf > 0) {
        hull() { case_slice(-1, rf); case_slice(0, rf); }
        for (k = [0 : n - 1]) hull() {
            case_slice(rf * (1 - cos(90 * k / n)),       rf * (1 - sin(90 * k / n)));
            case_slice(rf * (1 - cos(90 * (k + 1) / n)), rf * (1 - sin(90 * (k + 1) / n)));
        }
    }
    hull() { case_slice(rf > 0 ? rf : -1, 0); case_slice(max(h, rf) + 1, 0); }
}

// 上から見た外形: リングと扇形の外周を、接線でまっすぐつないだ形。斜面の先端は角丸
module footprint() {
    a0 = 45 - slope_span / 2;
    offset(r = edge_radius) offset(r = -edge_radius)
    hull() {
        circle(r = r_top);
        polygon(concat([[0, 0]], [
            for (i = [0 : 180]) let (a = a0 + slope_span * i / 180)
                [r_out * cos(a), r_out * sin(a)]
        ]));
    }
}

// カド置きの本体: 全周の斜面を、上の外形で切り抜く
module corner_body() {
    intersection() {
        rotate_extrude() slope_profile();
        translate([0, 0, -1]) linear_extrude(h + 2) footprint();
    }
}

// つまみ: 対角方向に立つ板。上がアーチ形で、リングの上面から斜面の途中まで
module grip_fin() {
    r0 = r_in + grip_gap;
    r1 = r0 + grip_length;
    rotate([0, 0, 45]) rotate([90, 0, 0])
        linear_extrude(grip_thickness, center = true) {
            translate([r0, 0]) square([r1 - r0, h]);
            translate([(r0 + r1) / 2, h])
                scale([(r1 - r0) / 2, max(grip_extra, 0.01)]) circle(1, $fn = 96);
        }
}

difference() {
    union() {
    if (grip) grip_fin();
    if (corner) {
        intersection() {
            corner_body();
            corner_region();
        }
    } else {
        rotate_extrude() slope_profile();
    }
    }
    translate([0, 0, -1]) cylinder(h = h + 2, r = r_in);
}

if (corner)
    echo(str("幅・奥行 = ", d + max(r_top, slope_span >= 90 ? r_out : r_out * cos(45 - slope_span / 2)), " mm / 内径 = ", 2 * r_in, " mm / 高さ = ", h, " mm"));
else
    echo(str("外径 = ", 2 * r_out, " mm / 内径 = ", 2 * r_in, " mm / 高さ = ", h, " mm"));
