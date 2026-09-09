#include <iostream>
#include <memory>
#include "Vpe.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;

// Funzione helper per avanzare di mezzo ciclo di clock
void tick(Vpe* top, VerilatedVcdC* tfp) {
    top->clk_i = 0;
    top->eval();
    if (tfp) tfp->dump(main_time++);

    top->clk_i = 1;
    top->eval();
    if (tfp) tfp->dump(main_time++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    auto top = std::make_unique<Vpe>();
    auto tfp = std::make_unique<VerilatedVcdC>();

    top->trace(tfp.get(), 99);
    tfp->open("pe_waveform.vcd");

    // 1. Fase di Reset
    top->rst_i = 1;
    top->data_i = 0;
    top->weight_i = 0;
    top->prevout_i = 0;

    for (int i = 0; i < 2; ++i) {
        tick(top.get(), tfp.get());
    }

    top->rst_i = 0;
    tick(top.get(), tfp.get());

    // 2. Applicazione Stimoli (Test operazione MAC)
    // Ciclo 1: Impostazione ingressi (data = 3, weight = 5, prevout = 10)
    top->data_i = 3;
    top->weight_i = 5;
    top->prevout_i = 10;
    tick(top.get(), tfp.get());

    // Ciclo 2: I registri interni catturano i valori.
    // Calcolo atteso alla combinatoria: 10 + (3 * 5) = 25
    top->data_i = 0; // Cambiamo gli ingressi per verificare la propagazione
    top->weight_i = 0;
    top->prevout_i = 0;
    tick(top.get(), tfp.get());

    // 3. Stampa e verifica dei risultati
    std::cout << "--- Risultati Simulazione ---" << std::endl;
    std::cout << "data_o   : " << static_cast<int>(top->data_o) << " (Atteso: 3)" << std::endl;
    std::cout << "result_o : " << top->result_o << " (Atteso: 25)" << std::endl;

    // Esegui ancora qualche ciclo prima di chiudere
    for (int i = 0; i < 4; ++i) {
        tick(top.get(), tfp.get());
    }

    tfp->close();
    return 0;
}