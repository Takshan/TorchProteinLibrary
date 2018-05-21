import torch
from torch.autograd import Function
from torch.autograd import Variable
from torch.nn.modules.module import Module
from Exposed import cppAngles2CoordsDihedral
import math

class Angles2CoordsDihedralFunction(Function):
	"""
	Protein angles -> coordinates function
	"""
	
	@staticmethod
	def forward(ctx, input, angles_length):
		ctx.angles_max_length = torch.max(angles_length)
		if len(input.size())==3:
			batch_size = input.size(0)
			output_coords_gpu = torch.DoubleTensor(batch_size, 3*(ctx.angles_max_length)).cuda()
			ctx.A = torch.DoubleTensor(batch_size, 16*ctx.angles_max_length).cuda()
		else:
			raise Exception('Angles2CoordsFunction: ', 'Incorrect input size:', input.size()) 

		output_coords_gpu.fill_(0.0)
		cppAngles2CoordsDihedral.Angles2Coords_forward( input,              #input angles
												output_coords_gpu,  #output coordinates
												angles_length, 
												ctx.A)
													
		if math.isnan(output_coords_gpu.sum()):
			raise(Exception('Angles2CoordsDihedralFunction: forward Nan'))		
		ctx.save_for_backward(input, angles_length)
		return output_coords_gpu
			
	@staticmethod
	def backward(ctx, gradOutput):
		input, angles_length = ctx.saved_tensors
		if len(input.size()) == 3:
			batch_size = input.size(0)
			gradInput_gpu = torch.DoubleTensor(batch_size, 2, ctx.angles_max_length).cuda()
			dr_dangle = torch.DoubleTensor(batch_size, 2, 3*(ctx.angles_max_length+1)*ctx.angles_max_length).cuda()
		else:
			raise(Exception('Angles2CoordsDihedralFunction: backward size', input.size()))		
		
		dr_dangle.fill_(0.0)
		gradInput_gpu.fill_(0.0)
		
		cppAngles2CoordsDihedral.Angles2Coords_backward(gradInput_gpu, gradOutput, input, angles_length, self.A, dr_dangle)
		
		if math.isnan(gradInput_gpu.sum()):
			print 'GradInput: ', gradInput_gpu
			print 'GradOutput: ', gradOutput
			raise(Exception('Angles2CoordsDihedralFunction: backward Nan'))		
		
		return gradInput_gpu, None

class Angles2CoordsDihedral(Module):
	def __init__(self):
		super(Angles2CoordsDihedral, self).__init__()
		
	def forward(self, input, angles_length):
		return Angles2CoordsDihedralFunction.apply(input, angles_length)