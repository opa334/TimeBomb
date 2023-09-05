#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

bool stringStartsWith(const char *str, const char* prefix)
{
	if (!str || !prefix) {
		return false;
	}

	size_t str_len = strlen(str);
	size_t prefix_len = strlen(prefix);

	if (str_len < prefix_len) {
		return false;
	}

	return !strncmp(str, prefix, prefix_len);
}

__attribute__((noinline, naked)) volatile kern_return_t shit_vm_protect(mach_port_name_t target, mach_vm_address_t address, mach_vm_size_t size, boolean_t set_maximum, vm_prot_t new_protection)
{
	__asm("mov x16, #0xFFFFFFFFFFFFFFF2");
	__asm("svc 0x80");
	__asm("ret");
}

kern_return_t shit_unprotect(vm_address_t addr, vm_size_t size)
{
	return shit_vm_protect(mach_task_self_, addr, size, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
}

kern_return_t shit_protect(vm_address_t addr, vm_size_t size)
{
	kern_return_t kr = shit_vm_protect(mach_task_self_, addr, size, false, VM_PROT_READ | VM_PROT_EXECUTE);
	if (kr != KERN_SUCCESS) return kr;
	return shit_vm_protect(mach_task_self_, addr, size, true, VM_PROT_READ | VM_PROT_EXECUTE);
}

#define UNPROTECT_COUNT 10000 // higher = more spinlocks
void triggerSpinlock(void)
{
	uint32_t execPathSize = PATH_MAX;
	char *execPath = malloc(execPathSize);
	_NSGetExecutablePath(execPath, &execPathSize);

	vm_address_t region = 0;
	struct vm_region_submap_short_info_64 info;
	mach_msg_type_number_t infoCount = VM_REGION_SUBMAP_SHORT_INFO_COUNT_64;
	int c = 0;
	while (true) {
		vm_size_t regionLength = 0;
		natural_t maxDepth = 99999;
		kern_return_t kr = vm_region_recurse_64(mach_task_self_, &region, &regionLength,
											&maxDepth,
											(vm_region_recurse_info_t)&info,
											&infoCount);
		if (kr != KERN_SUCCESS) break;
		vm_address_t regionEnd = region + regionLength;
		Dl_info dlInfo;
		dladdr((void *)region, &dlInfo);
		if (!stringStartsWith(dlInfo.dli_fname, "/private/preboot") && strcmp(dlInfo.dli_fname, execPath) != 0) {
			if ((bool)(info.protection & VM_PROT_EXECUTE) && !(bool)(info.protection & VM_PROT_WRITE)) {
				for (vm_address_t page = region & ~PAGE_MASK; page < regionEnd; page += 0x4000) {
					shit_unprotect(page, PAGE_SIZE);
					shit_protect(page, PAGE_SIZE);
					*(volatile uint64_t *)page;
					if (++c >= UNPROTECT_COUNT) break;
				}
			}
		}
		
		region = region + regionLength;
	}

	free(execPath);
}

%ctor {
	triggerSpinlock();
}