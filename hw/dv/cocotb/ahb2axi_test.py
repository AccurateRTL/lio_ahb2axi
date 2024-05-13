# Copyright AccurateRTL contributors.
# Licensed under the MIT License, see LICENSE for details.
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.triggers import FallingEdge, Timer
from cocotbext.ahb import AHBBus, AHBMaster, AHBMonitor
#from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from cocotbext.axi import AxiBus, AxiRam
import random
import math


async def generate_clock(dut):
    """Generate clock pulses."""
    for cycle in range(1000):
        dut.clk.value = 0
        await Timer(1, units="ns")
        dut.clk.value = 1
        await Timer(1, units="ns")

def rnd_val(bit: int = 0, zero: bool = True):
    if zero is True:
        return random.randint(0, (2**bit) - 1)
    else:
        return random.randint(1, (2**bit) - 1)


def pick_random_value(input_list):
    if input_list:
        return random.choice(input_list)
    else:
        return None  # Return None if the list is empty
    

@cocotb.test()
async def my_second_test(dut):
    N = 10
    data_width = 32
    mem_size_kib = 1
    
    """Try accessing the design."""
    dut.rst_n.value = 0
    
     # Map the bus monitor to the I/F slave_h* I/F
#    ahb_mon = AHBMonitor(
#        AHBBus.from_entity(dut), dut.clk, dut.rst_n
#    )
         
         
         
    ahb_lite_master = AHBMaster(
        AHBBus.from_entity(dut), dut.clk, dut.rst_n, def_val="0"
    )
    
    axi_ram = AxiRam(AxiBus.from_prefix(dut, ""), dut.clk, dut.rst_n, reset_active_level=False, size=2**16)
    
    
    
#    axil_master = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "axil"), dut.clk, dut.rst)
#    test_data = bytearray([x % 256 for x in range(4)])
       
    await cocotb.start(generate_clock(dut))  # run the clock "in the background"

    await Timer(10, units="ns")   # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"
    dut.rst_n.value = 1
    
    await Timer(100, units="ns")   # wait a bit 
    
    
    address   = [0x110,0x114,0x118,0x11c] 
    test_data = [0x1,0x2,0x3,0x4]
    size      = [4,4,4,4]

#    address   = [0x100] 
#    test_data = [[0x1,0x2,0x3,0x4]]
#    size      = [4]

    await ahb_lite_master.write(address, test_data, size, True)
    rd_data = await ahb_lite_master.read(address, size, True)
    for i in range(4):
      print(rd_data[i]['data'])  
        
     
#   for n in range(10):
#        await axil_master.write(0x110+n*4, test_data)
#        rd_data = await axil_master.read(0x110+n*4, 4)
#    for a in range(10):
#        

    
    address = random.sample(range(0, 2 * mem_size_kib * 1024, 8), N)
    value = [rnd_val(data_width) for _ in range(N)]
    size = [pick_random_value([1, 2, 4]) for _ in range(N)]
    
#    resp = await ahb_lite_master.write(address, value, size)
    
    await Timer(1, units="us")   # wait a bit
#    dut._log.info("my_signal_1 is %s", dut.my_signal_1.value)
 #   assert dut.my_signal_2.value[0] == 0, "my_signal_2[0] is not 0!"
