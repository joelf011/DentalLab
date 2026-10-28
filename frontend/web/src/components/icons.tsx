export type IconName =
  | 'layout'
  | 'clipboard'
  | 'package'
  | 'users'
  | 'building'
  | 'workflow'
  | 'layers'
  | 'user'
  | 'settings'
  | 'bell'
  | 'plus'
  | 'alert'
  | 'list'
  | 'image'
  | 'file'
  | 'file-text'
  | 'archive'
  | 'cube'
  | 'camera'
  | 'lock'
  | 'eye'
  | 'download'
  | 'upload'

const paths: Record<IconName, React.ReactNode> = {
  file: (
    <>
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z" />
      <path d="M14 2v6h6" />
    </>
  ),
  'file-text': (
    <>
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8Z" />
      <path d="M14 2v6h6M8 12h8M8 16h8M8 19h5" />
    </>
  ),
  archive: (
    <>
      <rect x="4" y="3" width="16" height="18" rx="2" />
      <path d="M10 3v3h3v3h-3v3h3v3M10 17h3v2h-3Z" />
    </>
  ),
  cube: (
    <>
      <path d="m12 2 9 5v10l-9 5-9-5V7Z" />
      <path d="m3 7 9 5 9-5M12 12v10" />
    </>
  ),
  camera: (
    <>
      <path d="M8 5 9.5 3h5L16 5h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z" />
      <circle cx="12" cy="13" r="4" />
    </>
  ),
  lock: (
    <>
      <rect x="4" y="10" width="16" height="11" rx="2" />
      <path d="M8 10V6a4 4 0 0 1 8 0v4M12 14v3" />
    </>
  ),
  eye: (
    <>
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z" />
      <circle cx="12" cy="12" r="3" />
    </>
  ),
  download: (
    <>
      <path d="M12 3v12m-5-5 5 5 5-5M4 16v5h16v-5" />
    </>
  ),
  upload: (
    <>
      <path d="M12 16V4m-5 5 5-5 5 5M4 16v5h16v-5" />
    </>
  ),
  layout: (
    <>
      <rect x="3" y="3" width="7" height="7" />
      <rect x="14" y="3" width="7" height="7" />
      <rect x="3" y="14" width="7" height="7" />
      <rect x="14" y="14" width="7" height="7" />
    </>
  ),
  clipboard: (
    <>
      <rect x="5" y="4" width="14" height="17" rx="2" />
      <path d="M9 4V2h6v2M8 10h8M8 14h8M8 18h5" />
    </>
  ),
  package: (
    <>
      <path d="m3 7 9-4 9 4-9 4-9-4Z" />
      <path d="M3 7v10l9 4 9-4V7M12 11v10" />
    </>
  ),
  users: (
    <>
      <circle cx="9" cy="8" r="3" />
      <circle cx="17" cy="9" r="2.5" />
      <path d="M3 20c0-4 2.5-6 6-6s6 2 6 6M15 15c3 0 5 1.8 5 5" />
    </>
  ),
  building: (
    <>
      <path d="M4 21V5l8-3 8 3v16M8 8h2M14 8h2M8 12h2M14 12h2M8 16h2M14 16h2M2 21h20" />
    </>
  ),
  workflow: (
    <>
      <rect x="3" y="3" width="6" height="5" rx="1" />
      <rect x="15" y="16" width="6" height="5" rx="1" />
      <path d="M9 5.5h5a4 4 0 0 1 4 4V16M15 18.5h-5a4 4 0 0 1-4-4V8" />
    </>
  ),
  layers: (
    <>
      <path d="m12 3 9 5-9 5-9-5 9-5Z" />
      <path d="m3 12 9 5 9-5M3 16l9 5 9-5" />
    </>
  ),
  user: (
    <>
      <circle cx="12" cy="8" r="4" />
      <path d="M4 21c0-5 3-8 8-8s8 3 8 8" />
    </>
  ),
  settings: (
    <>
      <circle cx="12" cy="12" r="3" />
      <path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2" />
    </>
  ),
  bell: (
    <>
      <path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" />
    </>
  ),
  plus: <path d="M12 5v14M5 12h14" />,
  alert: (
    <>
      <path d="M12 3 2 21h20L12 3Z" />
      <path d="M12 9v5M12 18h.01" />
    </>
  ),
  list: (
    <>
      <path d="M8 6h13M8 12h13M8 18h13" />
      <path d="M3 6h.01M3 12h.01M3 18h.01" />
    </>
  ),
  image: (
    <>
      <rect x="3" y="4" width="18" height="16" rx="2" />
      <circle cx="9" cy="10" r="2" />
      <path d="m21 15-5-5L5 20" />
    </>
  ),
}

export function AppIcon({
  name,
  className = 'h-5 w-5',
}: {
  name: IconName
  className?: string
}) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      className={`shrink-0 ${className}`}
    >
      {paths[name]}
    </svg>
  )
}

/** File extension determines the icon; unknown files remain a neutral document. */
export function fileIconName(filename: string): IconName {
  const extension = filename.split('.').pop()?.toLowerCase()
  if (
    [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'heic',
      'tiff',
      'bmp',
      'svg',
    ].includes(extension ?? '')
  )
    return 'image'
  if (['stl', 'obj', 'ply', '3mf'].includes(extension ?? '')) return 'cube'
  if (['zip', 'rar', '7z', 'tar', 'gz'].includes(extension ?? ''))
    return 'archive'
  if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'].includes(extension ?? ''))
    return 'file-text'
  return 'file'
}
