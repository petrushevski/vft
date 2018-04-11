import hou
import toolutils
import os
import logging
import time

"""
todo
    * pass parameters as attributes, to reduce overhead of kernel re-compilation
    * pass in arbitrary combination of hybrids, primitives and boolean-combine them
"""

# logging config
logging.basicConfig(level=logging.DEBUG) # set to logging.INFO to disable DEBUG logs
log = logging.getLogger(__name__)

# returns list of fractal nodes that are connected (upstream) to root node
def getInputFractalNodes(root):
    # node type names of all fractal nodes
    fractals_nodes = set( ["vft_bristorbrotIter", "vft_mandelbulbPower2Iter", "vft_mengerSpongeIter"] )

    all_input_nodes = root.inputAncestors()
    input_fractal_nodes = []

    # find fractal nodes in all input nodes
    for node in all_input_nodes:
        if node.type().name() in fractals_nodes:
            input_fractal_nodes.append(node)

    return input_fractal_nodes

# returns a connected node (downstream) which belongs to "vft generator" list
def getOutputNodeByTypeName(start_node, type_name=""):
    all_children_nodes = outputChildren(start_node)
    out = None

    for node in all_children_nodes:
        if node.type().name() == type_name:
            out = node
            break
    
    return out

# find all descending connected (downstream) nodes
def outputChildren(node):
    children = list( node.outputs() )
    for node in children:
        new_children = node.outputs()
        if len(new_children) == 0:
            break
        else:
            for child in new_children:
                children.append( child )
                outputChildren(child)
    
    return children

# helper func
def clStatementsToString(statements):
    return ";\n".join(statements) + ";\n"

# class that will generate fractal generation CL code that Houdini will read from a string parameter and will execute
class GenerateKernel(object):
    def __init__(self):
        self.vft_root_path = self.getVftRootFromPath( hou.getenv("HOUDINI_PATH") )
        self.vft_kernels_path = os.path.join(self.vft_root_path, "ocl/vft_kernels.cl")

        self.vft_kernels = None
        self.vft_kernels_parsed = None
    
    # this might not work on Windows
    # extracts path to VFT from os-style paths string
    def getVftRootFromPath(self, path):
        paths = path.split(":")
        
        # this will need to be changed if git repository name changes
        pattern = os.sep + "raymarching" + os.sep + "houdini"

        # find pattern in list of paths
        vft_root = ""
        for path in paths:
            if pattern in path:
                vft_root = path
                break
        
        return vft_root
    
    # loads vft_kernels.cl file into member variable
    def loadKernelsFileToMemberVar(self):
        start_time = time.time()
        with open(self.vft_kernels_path, 'r') as file:
            self.vft_kernels = file.read()


        log.debug("Kernels file loaded from disk in {0:.8f} seconds".format( time.time() - start_time ))
    
    # loads vft_kernels.cl into specified parm object (which should be string) - this function should be called by a button for (re)loading a parm
    def loadKernelsFileToParm(self, parm):
        if self.vft_kernels == None:
            self.loadKernelsFileToMemberVar()

        parm.set(self.vft_kernels)
    
    # loads vft_kernels.cl into member var - either from disk, or parm (if it is loaded there already)
    def loadKernelsFileFromParm(self, parm):
        if parm.eval() == "":
            log.debug("Loading member var from file")
            self.loadKernelsFileToMemberVar()
        else:
            log.debug("Loading member var from node parameter")
            self.vft_kernels = parm.eval()
    
    # parses vft_kernels.cl file and replaces PY_* macros and saves it into member varible
    def parseKernelsFile(self, fractal_attribs):
        start_time = time.time()
        self.vft_kernels_parsed = self.vft_kernels

        # generate fractal stack
        fractals_stack_token = "#define PY_FRACTAL_STACK"

        fractals_stack_cl_code = clStatementsToString( self.generateClFractalStack(fractal_attribs) )
        fractals_stack_cl_code = fractals_stack_token + "\n\n" + fractals_stack_cl_code

        self.vft_kernels_parsed = self.vft_kernels_parsed.replace(fractals_stack_token, fractals_stack_cl_code)


        log.debug("Kernels file parsed in {0:.8f} seconds".format( time.time() - start_time ))
    
    # returns a list of CL statements with fractal function calls from a list of fractal nodes
    def generateClFractalStack(self, fractal_attribs):
        # a dictionary mapping strings of arguments to OpenCL fractal function names
        args_dict = {
            "default" : "{0}(Z, de, P_in, log_lin, {1:.6f}f, (float4)({2:.1f}f, {3:.6f}f, {4:.6f}f, {5:.6f}f))",
            "mandelboxIter" : "{0}(Z, de, P_in, log_lin, {1:.6f}f, (float4)({2:.1f}f, {3:.6f}f, {4:.6f}f, {5:.6f}f), {6:.6f}f)",
            "mandelbulbIter" : "{0}(Z, de, P_in, log_lin, {1:.6f}f, (float4)({2:.1f}f, {3:.6f}f, {4:.6f}f, {5:.6f}f), {6:.6f}f)",
            "xenodreambuieIter" : "{0}(Z, de, P_in, log_lin, {1:.6f}f, (float4)({2:.1f}f, {3:.6f}f, {4:.6f}f, {5:.6f}f), {6:.6f}f, {7:.6f}f, {8:.6f}f)",
            "sierpinski3dIter" : "{0}(Z, de, P_in, log_lin, {1:.6f}f, (float4)({2:.1f}f, {3:.6f}f, {4:.6f}f, {5:.6f}f), {6:.6f}f, (float3)({7:.6f}f, {8:.6f}f, {9:.6f}f), (float3)({10:.6f}f, {11:.6f}f, {12:.6f}f))"
        }

        def args_format(args_dict, obj):
            # if a function has some custom arguments, then their formatting is specified here
            if obj.cl_function_name in args_dict:

                # this line is picking a string to be formatted from args_dict dictionary
                string = args_dict[obj.cl_function_name]

                if obj.cl_function_name == "mandelboxIter":
                    string = string.format( obj.cl_function_name, float(obj.parms["weight"]), float(obj.parms["julia_mode"]), float(obj.parms["juliax"]), float(obj.parms["juliay"]), float(obj.parms["juliaz"]), float(obj.parms["scale"]) )

                elif obj.cl_function_name == "mandelbulbIter":
                    string = string.format( obj.cl_function_name, float(obj.parms["weight"]), float(obj.parms["julia_mode"]), float(obj.parms["juliax"]), float(obj.parms["juliay"]), float(obj.parms["juliaz"]), float(obj.parms["power"]) )
                
                elif obj.cl_function_name == "xenodreambuieIter":
                    string = string.format( obj.cl_function_name, float(obj.parms["weight"]), float(obj.parms["julia_mode"]), float(obj.parms["juliax"]), float(obj.parms["juliay"]), float(obj.parms["juliaz"]), float(obj.parms["power"]), float(obj.parms["alpha"]), float(obj.parms["beta"]) )
                
                elif obj.cl_function_name == "sierpinski3dIter":
                    string = string.format( obj.cl_function_name, float(obj.parms["weight"]), float(obj.parms["julia_mode"]), float(obj.parms["juliax"]), float(obj.parms["juliay"]), float(obj.parms["juliaz"]), float(obj.parms["scale"]), float(obj.parms["offsetx"]), float(obj.parms["offsety"]), float(obj.parms["offsetz"]), float(obj.parms["rotx"]), float(obj.parms["roty"]), float(obj.parms["rotz"]) )

            # if function has not arguments mapping in args_dict, then it is considered to use default one
            else:
                string = args_dict["default"]
                string = string.format( obj.cl_function_name, float(obj.parms["weight"]), float(obj.parms["julia_mode"]), float(obj.parms["juliax"]), float(obj.parms["juliay"]), float(obj.parms["juliaz"]) )
            
            return string

        fractal_objects = []
        for attrib in fractal_attribs:
            obj = FractalObject()
            obj.attribToVars(attrib)
            fractal_objects.append(obj)

        # list which will hold CL fractal funcs calls
        stack = []

        for obj in fractal_objects:
            statement = args_format(args_dict, obj)
            stack.append(statement)

        return stack

# this func will do all the parsing and will set up the kernel parm in descendant opencl node
def fillKernelCodePythonSop():
    start_time = time.time()    
    me = hou.pwd()
    geo = me.geometry()
    kernels_parm = me.parm("vft_kernels")

    # find a opencl downstream node
    cl_node = getOutputNodeByTypeName(me, "opencl")

    # init a GenerateKernel object and init member var vft_kernels
    kernel = GenerateKernel()
    kernel.loadKernelsFileFromParm(kernels_parm)

    # get set of incoming fractals
    fractal_attribs = geo.findGlobalAttrib("fractal_name").strings()

    # do the parsing
    kernel.parseKernelsFile(fractal_attribs)

    # set vft_kernels_parsed to kernelcode parm in an opencl node if has changed
    cl_node_parm = cl_node.parm("kernelcode")
    old_cl_code = cl_node_parm.eval()

    if old_cl_code != kernel.vft_kernels_parsed:
        cl_node_parm.set(kernel.vft_kernels_parsed)
        log.debug("Kernel in OpenCL node updated")
    else:
        log.debug("Kernel in OpenCL is up to date")

    log.debug("Python SOP evaluated in {0:.8f} seconds \n\n".format( time.time() - start_time ))

# a class that will hold data and functionality for getting fractal data from detail attribute
class FractalObject(object):
    def __init__(self):
        # init member vars
        self.asset_name = None
        self.parent_name = None
        self.cl_function_name = None
        self.parms = {
            "weight" : 1.0,
            "julia_mode" : 0,
            "juliax" : 0.0,
            "juliay" : 0.0,
            "juliaz" : 0.0
        }
    
    # this will parse attribute string and will set member vars from it
    def attribToVars(self, attrib):
        attrib_list = attrib.split("|")

        self.asset_name = attrib_list[0]
        self.parent_name = attrib_list[1]

        self.cl_function_name = self.asset_name.split("_")[-1]

        parms_string = attrib_list[2]
        parms_list = parms_string.split(",")

        for item in parms_list:
            item_split = item.split(":")
            self.parms[ item_split[0] ] = item_split[1]

    # this will fill in member vars based on a node, it should be used inside of a fractal node
    def nodeToVars(self):
        node = hou.pwd()

        self.asset_name = node.parent().type().name()
        self.parent_name = node.parent().name()

        parms = node.parent().parms()
        for parm in parms:
            self.parms[ parm.name() ] = parm.eval()
    
    # this will serialize member vars into a string, which should be stored in detail attribute
    def varsToAttrib(self):
        parms_string = ""

        for key, value in self.parms.iteritems():
            parms_string += key + ":" + "{0:.6f}".format(value) + ","
        parms_string = parms_string[:-1] # remove the last comma
        
        attrib = "|".join( [self.asset_name, self.parent_name, parms_string] )
        return attrib
