// File: backend/src/utils/proxy.ts

import CIDRMatcher from 'cidr-matcher';
import { env } from '../core/index.js';

const trustedCIDRs = [env.DOCKER_SUBNET_1, env.DOCKER_SUBNET_2];
const matcher = new CIDRMatcher(trustedCIDRs);

export function isFromTrustedProxy(ip: string): boolean {
	return matcher.contains(ip);
}
