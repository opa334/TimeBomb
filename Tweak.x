#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "substrate.h"

CFDictionaryRef (*CNCopyCurrentNetworkInfo_orig)(CFStringRef interfaceName);
CFDictionaryRef CNCopyCurrentNetworkInfo_hook(CFStringRef interfaceName)
{
	return CNCopyCurrentNetworkInfo_orig(interfaceName);
}

Boolean (*SCNetworkReachabilityGetFlags_orig)(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);
Boolean SCNetworkReachabilityGetFlags_hook(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags)
{
	return SCNetworkReachabilityGetFlags_orig(target, flags);
}

CFAbsoluteTime (*CFAbsoluteTimeGetCurrent_orig)();
CFAbsoluteTime CFAbsoluteTimeGetCurrent_hook() {
    return CFAbsoluteTimeGetCurrent_orig();
}

time_t (*time_orig)(time_t *tloc);
time_t time_hook(time_t *tloc) {
    return time_orig(tloc);
}

%ctor {
	MSHookFunction(CNCopyCurrentNetworkInfo, (void *)&CNCopyCurrentNetworkInfo_hook, (void **)&CNCopyCurrentNetworkInfo_orig);
	MSHookFunction(SCNetworkReachabilityGetFlags, (void *)&SCNetworkReachabilityGetFlags_hook, (void **)&SCNetworkReachabilityGetFlags_orig);
	MSHookFunction(CFAbsoluteTimeGetCurrent, (void *)&CFAbsoluteTimeGetCurrent_hook, (void **)&CFAbsoluteTimeGetCurrent_orig);
	MSHookFunction(time, (void *)&time_hook, (void **)&time_orig);
}