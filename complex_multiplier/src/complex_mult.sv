module complex_mult_rounded (
    input  logic        clk_i,          // Тактовый сигнал
    input  logic        srst_i,         // Синхронный сброс
    input  logic [17:0] data_a_i_i,     // Реальная компонента a (18.0)
    input  logic [17:0] data_a_q_i,     // Мнимая компонента a (18.0)
    input  logic [17:0] data_b_i_i,     // Реальная компонента b (2.16)
    input  logic [17:0] data_b_q_i,     // Мнимая компонента b (2.16)
    output logic [17:0] data_i_o,       // Реальная компонента результата
    output logic [17:0] data_q_o        // Мнимая компонента результата
);

// =============================================
// Внутренние регистры (с явной инициализацией)
// =============================================
logic [17:0] a_i_reg1 = '0;
logic [17:0] a_q_reg1 = '0;
logic [17:0] b_i_reg1 = '0;
logic [17:0] b_q_reg1 = '0;

logic [35:0] mul_ai_bi = '0;
logic [35:0] mul_aq_bq = '0;
logic [35:0] mul_ai_bq = '0;
logic [35:0] mul_aq_bi = '0;

logic [36:0] sum_i = '0;
logic [36:0] sum_q = '0;

logic [3:0] pipe_v = '0;  // Конвейер валидности

// =============================================
// Основной конвейерный процесс
// =============================================
always_ff @(posedge clk_i) begin
    if (srst_i) begin
        // Синхронный сброс всех регистров
        pipe_v    <= '0;
        a_i_reg1  <= '0;
        a_q_reg1  <= '0;
        b_i_reg1  <= '0;
        b_q_reg1  <= '0;
        mul_ai_bi <= '0;
        mul_aq_bq <= '0;
        mul_ai_bq <= '0;
        mul_aq_bi <= '0;
        sum_i     <= '0;
        sum_q     <= '0;
    end else begin
        // Сдвиг конвейера валидности
        pipe_v <= {pipe_v[2:0], 1'b1};

        // Этап 1: Загрузка входных данных
        if (pipe_v[0]) begin
            a_i_reg1 <= data_a_i_i;
            a_q_reg1 <= data_a_q_i;
            b_i_reg1 <= data_b_i_i;
            b_q_reg1 <= data_b_q_i;
        end

        // Этап 2: Выполнение умножений
        if (pipe_v[1]) begin
            mul_ai_bi <= $signed(a_i_reg1) * $signed(b_i_reg1);  // A*B
            mul_aq_bq <= $signed(a_q_reg1) * $signed(b_q_reg1);  // a*b
            mul_ai_bq <= $signed(a_i_reg1) * $signed(b_q_reg1);  // A*b
            mul_aq_bi <= $signed(a_q_reg1) * $signed(b_i_reg1);  // a*B
        end

        // Этап 3: Суммирование компонент
        if (pipe_v[2]) begin
            sum_i <= $signed(mul_ai_bi) - $signed(mul_aq_bq);  // Re = A*B - a*b
            sum_q <= $signed(mul_ai_bq) + $signed(mul_aq_bi);  // Im = A*b + a*B
        end

        // Этап 4: Округление результата
        if (pipe_v[3]) begin
            data_i_o <= round_to_18(sum_i);
            data_q_o <= round_to_18(sum_q);
        end
    end
end

// =============================================
// Функция округления к ±∞ (аппаратно-оптимизированная)
// =============================================
function logic [17:0] round_to_18(input logic [36:0] value);
    logic        sign;
    logic [15:0] fractional;
    logic [20:0] integer_part;
    begin
        sign         = value[36];                   // Знак числа
        fractional   = value[15:0];                 // Дробная часть
        integer_part = value[36:16];                // Целая часть (21 бит)

        // Округление к ±∞
        if (fractional != 0) begin
            if (sign) integer_part -= 1;  // Отрицательные: -1.5 → -2
            else      integer_part += 1;  // Положительные: 1.5 → 2
        end

        // Обрезка до 18 бит (с учетом знака)
        round_to_18 = integer_part[17:0];
    end
endfunction

endmodule