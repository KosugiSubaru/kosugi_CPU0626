module mem_interface_line_1bit (
    input  wire i_data,
    output wire o_data
);

    // 1ビットの信号経路を定義する最小単位のモジュール
    // 機能的には単なる配線だが、上位モジュールのgenerate文で呼び出されることで
    // 論理合成後の回路図において16ビットのバス構造を視覚的に表現する
    assign o_data = i_data;

endmodule