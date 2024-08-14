import torch

a = torch.randn([2, 3, 4])
print("a: ", a)

b = torch.zeros(2*3*4)
print("b: ", b)

b.copy_(a.view(-1))
print("after copy b: ", b)

c = torch.zeros(2, 3, 4)
c.copy_(b.view(a.shape), non_blocking=True)
print(c)

print(torch.allclose(a, c))