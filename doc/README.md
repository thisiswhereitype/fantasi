# FANTASI documentation

This tutorial guides the reader through the usage of the
*FANTASI* (FAst NeTwork Analysis in SIlicon) hardware
accelerator, developed in partnership with [e-Therapeutics
PLC](https://www.etherapeutics.co.uk/). The work was funded
by EPSRC Impact Acceleration Account and EPSRC programme grant
[POETS](https://poets-project.org/). We start with the
[motivation](https://github.com/tuura/fantasi/tree/master/doc#motivation)
behind the project, then give an
[architectural overview](https://github.com/tuura/fantasi/tree/master/doc#architectural-overview)
of the accelerator, and finally we show how to build and use it, see
[prerequisites](https://github.com/tuura/fantasi/tree/master/doc#prerequisites)
and [building an accelerator](https://github.com/tuura/fantasi/tree/master/doc#building-an-accelerator-instance).
You can jump to the section you're interested in by clicking on the above links.

This project participated to the _Xilinx Open Hardware competition 2018_, for which
we made a video for presenting the project, see below.

<p align="center">
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=Z2w0hiHY3Us" target="_blank">
  <img src="http://img.youtube.com/vi/Z2w0hiHY3Us/0.jpg" alt="WATCH ME" width="480" height="360" border="10"/></a><br>
  The YouTube video of the FANTASI project. Click on the figure to play it!
</p>

We prototyped the accelerator on the _Altera DE4_ and _Xilinx Virtex7_ boards. This
tutorial also guides the reader through the synthesis of a complete instance of the
accelerator on these two boards.

## Motivation

This project is motivated by the area of *computational drug discovery*. In
this area, biological systems are modelled by protein-protein interaction (PPI)
networks [[1]](https://github.com/tuura/fantasi/tree/master/doc#basic-references) (large-scale graphs),
which are analysed for collecting statistics
and information that are used in pharmacological laboratories for a more
effective discovery of drugs. Watch the below video to have a deeper insight
of the drug discovery process, pionereed by *e-Therapeutics PLC*.

<p align="center">
  <a href="http://www.youtube.com/watch?feature=player_embedded&v=wQFpTtuzrgA" target="_blank">
  <img src="http://img.youtube.com/vi/wQFpTtuzrgA/0.jpg" alt="WATCH ME" width="480" height="360" border="10"/></a><br>
  The YouTube video of the drug discovery process. Click on the figure to play it!
</p>

Conventional computer architectures cannot process such large graphs
efficiently. The latter are stored in wide and slow off-chip memories, which
have to be queried continuously due to irregular memory accesses typical
of graph-related algorithms (e.g. graph traversal). To overcome this issue
imposed by the memory-bandwidth, we designed an hardware accelerator where
a graph is mapped into a digital circuit, where nodes are individual memory
elements (flip-flop) and arcs are combinational paths between these elements,
and is stimulated by an had-hoc infstracture with the purpose of extracting
statistic from the graph such as connectedness, resilience, etc.

<p align="center">
  <img src="https://github.com/tuura/fantasi/blob/master/doc/fig/speed.png" width="500" border="10"/></a><br>
  Fig. 1. Comparison of network analysis performance.
</p>

Figure 2 shows the scalability of the prototyped FANTASI accelerator
versus a software implementation in C++ for the drug discovery analysis. The
number of active edges (|E|) in a realistic PPI network is varied and
calculated execution time are shown. The plot highlights two aspects:
(a) The accelerator delivers a speed improvement of 2/3 orders of magnitude
depending on |E|. (b) While software execution time scales linearly with |E|,
the accelerator execution time slightly decreases, as the higher connectivity
reduces the network diameter, and also the corresponding time to fully
explore all PPI paths thanks to hardware parallelism.

The FANTASI accelerator is important as it highlights the benefits of
having a network of interconnected processing units, which in this case
are represented by flip-flop registers, that can operate concurrently. It
represents a demonstration, at a much lower scale, of the processing capability
of many-cores architectures, such as the [POETS](https://poets-project.org/).

## Architectural overview

The FANTASI accelerator relies on a mechanical, and
automated, process to map an *application network*
(in this case the Protein to Protein Interaction network
[[1]](https://github.com/tuura/fantasi/tree/master/doc#basic-references))
into a digital circuit. Figure 2 shows an example of this process: the
nodes of a network are converted into flip-flop registers, which are
interconnected according to the connections specified in the application
network. The OR gates join multiple incoming connections to a register, and
propagate messages between registers for computing the network resilience,
given by the average shortest path of the network. The latter is important
for the process of drug discovery.

<p align="center">
  <img src="https://github.com/tuura/fantasi/blob/master/doc/fig/graph.png" width="720" border="10"/></a><br>
  Fig. 2. The process of mapping a graph to a digital circuit.
</p>

The basic idea behind representing graphs using flip-flops and
combinational paths is that we wish to perform graph traversal by
propagating logic high values between flip-flops. The logic state of
each flip-flop therefore indicates whether a given vertex has been
visited (logic high) or not (logic low). To propagate a 'visited' state
between flip-flops, we OR the outputs of all vertex neighbours and use
it as an input to the vertex flip-flop. For further details, refer to
[[2]](https://github.com/tuura/fantasi/tree/master/doc#basic-references).

Figure 3, in turn, shows an high-level view of the FANTASI infrastructure (on one of
the board that we used: Altera DE4). The
digital circuit of the application network is at the core of the
accelerator, highlighted with a red dashed line. The *hardware graph*
is encapsulated by the control circuitry to enable/disable selected nodes,
coordinate computation, and read shortest-path computation results. An
on-chip software processor (NIOS II) is also included to communicate with
the host computer and provide an Application Programming Interface (API)
for network processing. The basic idea of the FANTASI accelerator is to allow
the reconfiguration of the network at runtime, in order to run multiple analyisis
on the same network under different configurations, without requiring the network
resynthesis. Each configuration is identified by a set of nodes that are disabled.

<p align="center">
  <img src="https://github.com/tuura/fantasi/blob/master/doc/fig/hw.png" width="840" border="10"/></a><br>
  Fig. 3. The FANTASI hardware accelerator infrastructure.
</p>

For our experiments, we used the *Altera DE4* and the *Xilinx Virtex 7* boards.
The host computer connects to the boards via a USB cable
that uses the JTAG UART interface. This is used for downloading the C code to
the soft-processor (NIOS II and Microblaze, respectively), which provides the API
for graph processing. The host computer, instead, interfaces with the user of the
FANTASI accelerator.

## Prerequisites

Here is what you need to build and use the `fantasi` tool of this repository:

* [**Stack**](https://docs.haskellstack.org/en/stable/README/) - the simplest
way to install the `fantasi` tool is by using Stack. It can install GHC, and
download all the packages needed to building the `fantasi` tool automatically.
* [**GHC compiler 8.2.2**](https://www.haskell.org/ghc/) - the
Glasgow Haskell compiler.
* [**Pangraph library v0.1.1.5**](https://hackage.haskell.org/package/pangraph) -
The pangraph library, available on hackage on the link provided, is needed
for parsing an application graph (in GraphML format).

For installing the `fantasi` tool globally, you need to run the following command.
```
stack install
fantasi --help
```

For local install:
```
stack build
stack exec fantasi -- --help
```

The second command `fantasi --help` displays the help of the tool, which is shown below:
```
Usage: fantasi [graphml file]
  -n FILEPATH  --graph-name=FILEPATH  VHDL graph output file-path
  -s FILEPATH  --sim-name=FILEPATH    VHDL simulation environment output file-path
  -h           --help                 Show this help message
  -v           --version              Show version of Fantasi
```

We tested the FANTASI accelerator on an Altera and a Xilinx boards. To use the
accelerator using the Altera tool-chain and hardware, you will need the following:

* **An Altera FPGA board** - in our experiments, we used the Altera DE4
board that embeds the Stratix IV FPGA (EP4SGX230KF40C2). However, any FPGA by
Altera can be used.
* [**Quartus Prime
Software**](https://www.altera.com/downloads/download-center.html) - the
Altera design environment for the usage of any Altera FPGA board. We
suggest to download the latest version of the software currently available. The
lite edition version allows the compilation and synthesis of hardware into some
of the Altera FPGA boards available. However, a license is required for the usage
of the latest and bigger FPGA, such as the one that we used. In our experiments,
we used the Quartus v16.1.
* [**NIOS II
devkit**](https://www.altera.com/products/processors/overview.html) -
the NIOS II is a software processor that can be synthesised in any Altera
FPGA. The development kit available with Quartus can be used to customise
and synthesise the processor into the FPGA.

On the other hand, to use the accelerator on a Xilinx board, you will need:

* **A Xilinx FPGA board** - in our experiments, we used the Xilinx Virtex 7
board. However, any FPGA by Xilinx can be used.

* [**Xilinx Vivado**](https://www.xilinx.com/support/download.html) - the
Xilinx design environment for the usage of any Xilinx FPGA board. We
suggest to download the latest version of the software currently available. A license
is required for the usage of the latest and bigger FPGA, such as the one that we used.
In our experiments, we used the Vivado 2018.1.

* [**Xilinx SDSoC**](https://www.xilinx.com/support/download.html) - This is the
software development kit to develop, compile, and upload software in the Xilinx
Microblaze processor, which is used for controlling the FANTASI accelerator.

For more information on how to install the above tools, refer to the official
documentation.

## Building an accelerator instance

In the previous section of the tutorial, we described the materials that are
needed to start using the FANTASI accelerator. In this section, we describe a
step-by-step guide that show how it can be used.

### Generating FPGA bitstream

* **1.** Get a [GraphML](http://graphml.graphdrawing.org/) file describing
the network for analysis. As an example, the application network in Figure
2 is described as below:

```
<?xml version="1.0" encoding="UTF-8"?>
<graphml>
  <graph id="G" edgedefault="undirected">
    <node id="A"/>
    <node id="B"/>
    <node id="C"/>
    <node id="D"/>
    <edge source="A" target="C" directed="false"/>
    <edge source="C" target="B" directed="false"/>
    <edge source="B" target="D" directed="false"/>
    <edge source="A" target="D" directed="false"/>
  </graph>
</graphml>
```

* **2.(Altera)** The Nios development kit can be used from within Quartus to generate
a VHDL entity of the Nios II software processor. For simplicity, we provide
all the dependencies (inside the `dependencies/` folder of the repository)
needed to generate the FPGA bitstream of the FANTASI accelerator, including the
top level entity (`TOP.vhdl`) where an instance of the Nios II processor is connected
to the modules for the drug discovery analysis. The top entity file needs to be customised
according to the network that one wants to analyse (see next iteration).

* **2.(Xilinx)** The Xilinx Vivado tool can be used to generate the VHDL entity of
the Microblaze software processor, and for all the modules needed for the communication
between the host computer, the soft processor and the accelerator. We provide the file
[`top.vhd`](../dependencies/Xilinx_virtex7/top.vhd) as example of all modules needed
for the accelerator to function correctly. We suggest the reader to watch this
[video](https://www.youtube.com/results?search_query=vivado+microblaze+tutorial)
in order to learn how to use the Vivado tool, synthesise an instance of the 
Microblaze processor, and upload software on it using the Eclipse SDK.
*Note:* we suggest to instantiate the maximum amount of memory for the Microblaze
processor (128KB), as we will fully use it with our API.

* **3.** Run the Bash script [`script.sh`](../script.sh) to generate the hardware network
(output file: `graph.vhdl`, see Figure 2), the modules for the drug analysis
(output file: `sim-environment.vhdl`, see Figure 3), and for modifying the top
level entity of the whole HW design (named `dependencies/TOP.vhd`).

```
./script.sh [graphml file] [fantasi tool] [top level VHDL entity]
```

* **4.(Altera)** Create a new project in Quartus and select the FPGA that
you want to use. In this tutorial, we assume the usage of the Stratix IV FPGA
(EP4SGX230KF40C2), so that to enjoy the ready-to-use Nios II processor instance
in `dependencies/`. Afterwards, import the generated files (`graph.vhdl` and
`sim-environment.vhdl`), and the content of the `dependencies/` folder into
the Quartus project, including the `constraints.sdc` file. Finally, set the
file `TOP.vhd` as top level entity of the project. **Note:** in order to import
the Nios II processor and the pll module, you need to import into quartus the
files with extension `.qip`, which can be found in the corresponding folders.

* **4.(Xilinx)** If you followed the step 2 (Xilinx). You will now have a working
instance of the Microblaze processor. All you need to do now is importing the files
[`FSM.vhdl`](../dependencies/FSM.vhdl) and [`FSM-enable-nodes.vhdl`](../dependencies/FSM-enable-nodes.vhd)
and their dependencies using the IP integrator, and size the input/output of the GPIOs using the Xilinx
IPs named _slice_ and _concat_ to connect the accelerator to the software processor.

* **5.(Altera)** Run the compilation process in Quartus, and then program the
generated bistream file into the FPGA. The expected compilation time for a network
composed of about 1k nodes is of 20 minutes.

* **5.(Xilinx)** Generate the bitstream in Vivado, and then launch the SDK in order
to be able to upload the bitstream into the board.

As a result, the FANTASI accelerator should be mapped onto the FPGA.

### Downloading NIOS Software

If you followed the previous steps, now you should have the FANTASI
accelerator mapped onto the FPGA. Now, we will have to download the C-based API into the
Nios II processor, which we will use as interface to the FANTASI accelerator from an
external host computer. To do this, open the *Eclipse* development
environment plugin embedded within Quartus: under the tab `Tools -> Nios II
Software Build Tools for Eclipse`.

* **1.** In the repository, you can find the C-based API ready to compile,
build and download into the Nios II processor, see file `nios-API.c`. To
use this API, first you will need to create a project inside the `Nios
II Software Build Tools for Eclipse` plugin. The project that is created
is divided in 2 sub-projects: (1) the first one contains the application
that you want to run in the Nios II processor, (2) the second one has
as suffix '_BSP', which stands for Board Support Package, and contains
the low level drivers that are needed to interface with the FPGA board.
To create this two projects, click on the tab `File ->
Nios II Application and BSP from Template` from within `Eclipse` design
environment. In the opened window (see Fig. 4),
select the SOPC file (file `dependencies/niosII/niosII.sopcinfo` of the repo,
see note below), write a name for the project (let's call it 'FANTASI'),
and select 'Blank Project' as project template.

<p align="center">
  <img src="https://github.com/tuura/fantasi/blob/master/doc/fig/nios-projects.png" width="450" border="10"/></a><br>
  Fig. 4. Nios II Application and BSP from Template.
</p>

*Note:* the file 'niosII.sopcinfo' provided in this repository in `dependencies/niosII/`
works specifically with the FPGA (Stratix IV EP4SGX230KF40C2). If you want to
use a different board, you will have to generate the Nios II processor by
following this tutorial: [Generate your own Nios II processor](https://github.com/tuura/fantasi/tree/master/doc#generate-your-own-nios-ii-processor).

* **2.** Once that you created the Eclipse projects, insert the file
`nios-API.c`, provided inside the repository, inside the 'FANTASI'
(non 'FANTASI_BSP') project. This file contains the API for accessing the
modules for the drug discovery analysis, and it is ready to be compiled, built
and downloaded into the Nios II processor for its execution.

* **3.** The next step is to create the 'Run configuration' properties
within `Eclipse` for building the project and download it into the Nios
II processor. To do this, click on `Run -> Run Configurations...` (see
Fig. 5). Next, right-click on the tab group `Nios II Hardware -> New`. Under
the tab 'Project', select the 'FANTASI' project in `Project name`, and
select the executable file with the extension '.elf', which is present
within the 'FANTASI' project in Eclipse upon compilation. Under the tab
'Target Connection', enable the following checkboxes: `Ignore mismatched
system ID` and `Ignore mismatched system timestamp`. You should see the
board within the `Connections` section under this tab, if not, try to
`Refresh connections`. Finally, click `Apply` and `Run`.

<p align="center">
  <img src="https://github.com/tuura/fantasi/blob/master/doc/fig/nios-configurations.png" width="750" border="10"/></a><br>
  Fig. 5. Eclipse window 'Run Configurations'.
</p>

As a result, the API interface should be now up and running. The Eclipse
plugin GUI will display the console of the Nios II processor in the `Console`
section. Read through the next section for some instructions on how to use
the accelerator.

### Downloading Microblaze Software

The steps that need to be performed in the Xilinx SDK are similar to the ones followed
for using the Altera NIOS II software processor. Again, we refer the reader to this
[video](https://www.youtube.com/results?search_query=vivado+microblaze+tutorial),
for learning how to use the Xilinx SDSoC and upload software into the Microblaze.

The API for using the FANTASI accelerator via this processor is provided, see
[`microblaze-API.c`](../microblaze-API.c).

## Using the accelerator

**How to run commands on the FANTASI API?** At this point, the Nios II
processor is ready to accept commands for running drug discovery analysis
over the synthesised network. The simplest way to use the accelerator is
via the `Console` within Eclipse environment. Otherwise, one could use
the tool `nios2-terminal` (provided inside the Quartus installation folder
`~/intelFPGA/[Quartus-version]/quartus/[OS-used]/`) to connect the terminal
to the FPGA board, and to run the FANTASI API provided. If you want to use
the terminal, you need to run the `nios2-terminal` in order to be prompted
to use the terminal as FANTASI command line.


**Which commands are available?** Find below the help of the FANTASI API.
```
Commands:
  start                          Run a simulation with all the nodes enabled
  test-drug 'n' -- [off nodes]   Run a simulation with the following 'n' nodes disabled in the form of '5 100 1 305'
                                   Example: test-drug 3 -- 5 10 946
  random 'n' 'm'                 Run 'n' simulations, removing 'm' random nodes at every run
  random-set 'from' 'to' 'n'     Remove 'n' independently chosen sets of size k, for k = 'from' .. 'to'
  growing-set 'to' 'n'           Remove 'n' growing sets of size k, for k = 1 .. 'to', starting
                                   with fixed random permutations as seeds for the growing sets
  force 'to'                     Remove sets of size k, for k = 1 .. 'to', where each node added into the
                                   set maximises the impact of the network
  result                         Display the result
  reset                          Reset the network, the register that contain the result, and the shift register
  stat                           Print number of nodes of the network
  help                           Print help of the tool
```

The Microblaze API contains lees functions. This is because the amount of local memory
of the processor does not allow to use many functions of the C std library (such as the scanf).
However, one can easily connect the Microblaze processor to an external DRAM memory in
order to extend the API.

**Examples**
* By running `start`, you will compute the average shortest path of the networks with all the nodes
enabled.
* With the command `test-drug 3 -- 10 60 99`, you will compute the
average shortest path (and the impact on the resilience of the network)
with the nodes with indices {10, 60, 99} are disabled.

**Known issues**
* The `nios2-terminal` tool, in linux, does not display the characters introduced
by the keyboard. The characters will still be recognised.

## Generate your own Nios II processor

The above instructions have walked you through synthesizing an accelerator
instance using the pre-built NIOS processor included in this repository. If
you wish to synthesize and bundle your own NIOS processor (because you have
difference performance requirements, require additional ports or else) then
you can follow the steps below:

NIOS processors can be generated using the _Qsys System Integration Tool_
within Quartus (accessible through the _Tools_ menu). The accelerator requires
a NIOS system with the following (minimum) set of components:

| Name                        | Library component              | Instance Name | Parameters                 |
|:----------------------------|:-------------------------------|:--------------|:---------------------------|
| On-Chip Memory (RAM or ROM) | `altera_avalon_onchip_memory2` | -             | RAM (204800 bytes minimum) |
| JTAG UART                   | `altera_avalon_jtag_uart`      | -             | -                          |
| Clock Source                | `clock_source`                 | -             | -                          |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `input0`      | 32-bits (inputs)           |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `input1`      | 32-bits (inputs)           |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `input2`      | 32-bits (inputs)           |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `input3`      | 32-bits (inputs)           |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `output0`     | 32-bits (outputs)          |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `output1`     | 32-bits (outputs)          |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `output2`     | 32-bits (outputs)          |
| PIO (Parallel I/O)          | `altera_avalon_pio`            | `output3`     | 32-bits (outputs)          |
| Nios II Processor           | `altera_nios2_gen2`            | -             | -                          |

Blank fields under _Instance Name_ and _Parameters_ indicate don't cares and
(default parameters, respectively.

The connections between the modules above must be configured under in the
_Connections_ column in the component list view. _Qsys_ will connect `clk` and
`reset` pins automatically but you must ensure that the Nios processor's
`data_master` and `instruction_master` ports (both of the type _Avalon Memory
Mapped Master_) are connected to all ports with the type _Avalon Memory Mapped
Slave_ in other modules.

The repository contains a _Qsys_ system file
[`niosII.qsys`](../dependencies/Alterta_DE4/niosII/niosII.qsys) with the above
configuration. This may be an easier starting point than putting the system
together from scratch.

After adding the various modules of the system and configuring their
connections, regenerate base memory addresses by clicking the _System_ menu
then _Assign Base Addresses_.

The system should now be ready for synthesis. Press _Generate HDL..._ then
_Generate_ on the following dialog. _Qsys_ will then generate a NIOS system
with 4 inputs and 4 output ports that you can integrate into the accelerator's
HDL source code.


## Basic references

[1] M. P. Young et al. *Chapter 3. Drug Molecules and Biology: Network and
Systems Aspects*, in RSC Drug Discovery, pp. 32-49, 2012.

[2] A. Mokhov et al. *Language and Hardware Acceleration Backend for Graph
Processing*, Forum on specification & Design Languages, 2017.
