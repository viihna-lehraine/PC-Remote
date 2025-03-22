// File: backend/src/utils/proxy.ts

import CIDRMatcher from 'cidr-matcher';
import { env } from '../core/index.js';

const trustedCIDRs = [env.DOCKER_SUBNET];
const matcher = new CIDRMatcher(trustedCIDRs);

export function isFromTrustedProxy(ip: string): boolean {
	return matcher.contains(ip);
}
