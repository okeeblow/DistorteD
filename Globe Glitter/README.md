Globe Glitter is a [surrogate key](https://en.wikipedia.org/wiki/Surrogate_key) library for Ruby supporting a plethora of identifiers collectively known as [UUIDs and GUIDs](https://en.wikipedia.org/wiki/Universally_unique_identifier) which individually encode an intersection point between some two dimensions which vary depending on use case.

## Theory

UUIDs hail from the world of [distributed computing](https://en.wikipedia.org/wiki/Distributed_computing) as a way to identify [remote procedure calls](https://en.wikipedia.org/wiki/Remote_procedure_call) by encoding spatial information (i.e. the identity of a message's source computer) plus temporal information (i.e. the time a message was sent) into a form that may be decoded by any receiving computer.

The dual names for this concept (UUID vs. GUID) are our first clue that we're about to stumble into some deep, deep lore. Globe Glitter is my attempt to understand why the modern "UUID" standards are the way they are by implementing their historical incarnations, many of which live on today as well-known identifiers for files created on those systems. A prominent example is how developers working with time-based media may end up having to [identify audio and video codecs using Microsoft-style "GUIDs"](https://gix.github.io/media-types/) even on non-Microsoft systems.

The UUID standards documents do a poor job of explaining their legacy and even add some confusion of their own. The first document anyone is likely to find is [IETF Standards Track RFC 4122](https://www.ietf.org/rfc/rfc4122.txt) (published July 2005) which describes the same standard as [ITU-T Recommendation X.667](https://www.itu.int/rec/T-REC-X.667) (first published September 2004). Those dates should be a clue as to how much ambiguity we're about to run into, because they "standardize" something that had been in use for roughly two decades by the time those document were published.

## Questions

Reading the modern IETF/ITU UUID standards documents left me with several questions:

- What is the most accurate but most generic way to describe what a UUID actually is? Many definitions found on the web focus on the String representation only. (Hint: My attempt at answering this is in the first sentence of this document)
- When did the naming convention split between calling them UUIDs versus calling them GUIDs? The modern standards documents define them as synonyms. Was there ever a functional difference between the two, or was "GUID" just Microsoft's attempt to be legally clear of Apollo intellectual property after hiring away one of its co-founders?
- What are the "holes" in the modern standards documents? There are several places where RFC 4122 / ITU-T Rec. X.667 handwave earlier UUID/GUID formats, and I found like to understand what those were and what they were for. Examples include:
  - the brief mention of the "DCE Security" version-bit without describing when one would want to use it.
  - the reserved "NCS backward compatibility" variant-bit.
  - the reserved "Microsoft Corporation backward compatibility" variant-bit.

## History

To answer my questions, I had to study the history of the UUID. We can't study the history of the UUID without studying the history of RPC, and studying the various competing RPC systems of the 1980s quickly gets us wrapped up in the [Unix Wars](https://en.wikipedia.org/wiki/Unix_wars) due to distributed computing's inherent reliance on computer networking and the influence of DARPA dollars at that time. Please note that this is still a README about a UUID library and is not intended to be an exhaustive history lesson on Unix and its various derivitives. I've included the parts that I think are most relevant to understanding the '80s computing landscape in which Apollo and its RPC systems existed.


### 1969

Bell Laboratories pulls out of the [Multics](https://en.wikipedia.org/wiki/Multics) project.

### 1969~1979, Bell Labs

Ken Thompson, Dennis Ritchie, and others within Bell Laboratories develop and re-develop [The UNIX Time-Sharing System](https://worldradiohistory.com/Archive-Bell-System-Technical-Journal/70s/Bell-System-Technical-Journal-1978-6.pdf#page=181) as a platform to conduct their [programming language research](https://en.wikipedia.org/wiki/Research_Unix). This has made a lot of people very angry and been widely regarded as a bad move.

UNIX ["Version 0"](https://livingcomputers.org/Blog/Restoring-UNIX-v0-on-a-PDP-7-A-look-behind-the-sce.aspx) is written in PDP-7 assembly and hosted programs written in the B language. 1970's PDP-11 port of UNIX allowed for more features to be added to B, becoming "New B" by 1971 and eventually "C" in 1972. Version 4 of Research UNIX was then itself rewritten in C and was the first to be licensed to educational institutions. Version 6 of Research UNIX was the first to be licensed to commercial users and the first to be ported to a non-PDP minicomputer. Version 7 of Research UNIX in 1979 continued the portability trend to VAX, successor to the PDP family, and to many early microcomputer platforms that were just starting to appear.

### 1974~1979, Berkeley

The University of California, Berkeley becomes one of those outside UNIX licensees in January 1974 with installation of Version 4 Unix on a PDP-11/45. Ken Thompson joins Berkeley in 1975 as a visiting professor on a one-year sabbatical from Bell Labs. He brings Version 6 of Research UNIX with him along with his knowledge of its internals, using it as a platform to develop an implementation of the Pascal programming language on a PDP-11/70. Bill Joy and Chuck Haley arrive at Berkeley the same year and take an interest in Thompson's Pascal work. With the conclusion of Thompson's sabbatical and his departure from Berkeley, Joy and Haley become responsible for upkeep of the Unix installation and integration of changes sent on tape from Bell Labs. Berkeley's homegrown enhancements to Research Unix — including the Pascal compiler — become the "Berkeley Software Distribution", and [1BSD tapes](https://archive.org/details/1bsd.tar_201503) are mailed to other institutions beginning March 9th 1978. See Marshall Kirk McKusick's [Twenty Years of Berkeley Unix (1999)](https://www.oreilly.com/openbook/opensources/book/kirkmck.html) for more detail.

### 1980

[Apollo Computer](https://en.wikipedia.org/wiki/Apollo_Computer) is founded in [Chelmsford, Massachusetts](https://www.hpmuseum.net/divisions.php?did=28), with [Paul J. Leach](https://www.linkedin.com/in/pauljleach) on its engineering team. He is not the only person working on their distributed computing architecture, but his name comes up a lot and he is responsible for a twist in the story later.

### 1981

#### February

[Apollo Computer's DOMAIN Architecture](http://www.bitsavers.org/pdf/apollo/Apollo_DOMAIN_Architecture_Feb81.pdf) describes the architecture's [network object namespace](http://www.bitsavers.org/pdf/apollo/Apollo_DOMAIN_Architecture_Feb81.pdf#page=4).

> Instead of a machine level address space, such as the 24 bit address space of the Motorola 68000, we talk about a 96 bit network wide global object address space. Our thinking here is that objects are very large entities that are 32 bits in length and whose location should be anywhere on the network. This 96 bit network wide object address space is the fundamental. sy·stem address in the Apollo DOMAIN system, and is designed to accommodate various machine level addressspaces.

…and the technical implementation of that namespace using the [UID structure](http://www.bitsavers.org/pdf/apollo/Apollo_DOMAIN_Architecture_Feb81.pdf#page=13) (Not UUID yet!)

> The system global namespace is a 96 bit address space comprised of a unique ID (UID) which is 64 bits and an offset which is 32 bits wide. The 64 bit UID is unique in space and time. It is unique in space in that it includes an encoding of the machine's serial number and it is unique in time in the sense that it includes the time at which the name was created. This guarantees that for all time in the future and for all machines that Apollo builds, no two machines will ever create the same UID, hence the term unique ID.

> UIDs are names of objects. Objects are used to hold programs, files, and various other entities in the Apolle system. An object is a linear 32 bit address space, byte addressable, and can be located generally any place on the network. Objects are the primary focus for the Apollo DOMAIN system and are cached into the process address space provided by the Motorola 68000.

#### March 27

Apollo release the first version (SR1 or Software Release 1) of their DOMAIN Architecture, with individual nodes running their AEGIS operating system. AEGIS is UNIX-like, but AEGIS is *not* UNIX.  TODO: Find SR1 manual

### 1982

#### February 24

Sun Microsystems is founded to commercialize the [Stanford User Network workstation](http://i.stanford.edu/pub/cstr/reports/csl/tr/82/229/CSL-TR-82-229.pdf) with Bill Joy bringing his experience with BSD. 

#### August 18

[UIDs as Internal Names in a Distributed File System](https://dl.acm.org/doi/pdf/10.1145/800220.806679#page=3) by Paul J. Leach, Bernard L. Stumpf, James A. Hamilton, and Paul H. Levine describes implementation details of the UID for the ACM sumposium on Principles of Distributed Computing (PODC '82).

> AEGIS UIDs are 64 bit structures, containing a 36 bit creation time, a 20 bit node ID, and 8 other bits whose use is described later. UIDs possess the addressing aspects of a capability, but without the protections aspects [FABR 74]. Or, a UID can be thought of as the absolute address of an object in a 64 bit address space.

#### August 24

Settlement of [United States of America v. Western Electric Company, Incorporated, and American Telephone and Telegraph Company](https://web.archive.org/web/20060830041121/http://members.cox.net/hwilkerson/documents/AT%26T_Consent_Decree.pdf) replaces the previous 1950s-era operating rules for AT&T, requiring the breakup of the Bell System into several smaller Regional Bell Operating Companies.

### 1984

[The Architecture and Applications of the Apollo Domain](https://cl-pdx.com/static/The-Apollo-Domain-Operating-System.pdf#page=4) by David L. Nelson and Paul J. Leach describes UID for IEEE's Computer Graphics & Applications magazine.

> The [Apollo Computer's Domain] system assigns to each object a 64-bit, unique identifier string, or UID, which it creates by concatenating the unique node ID of the node generating the object with a time stamp from the node's timer. The UID is the mechanism by which the object is located. See Leach et al [the 1982 document] for a complete description of the use of UIDs in the Domain distributed file system.

> The user refers to an object with a text string, or pathname. The Domain system's naming server then translates the pathname into the object's UID.

### 1985

#### March 12–14

[The File System of an Integrated Local Network](https://dl.acm.org/doi/pdf/10.1145/320599.320696), Paul J. Leach, Paul H. Levlne, James A. Hamllton, and Bernard L. Stumpf describes the UID-based file system for the 1985 ACM Computer Science Conference.

[File System Overview](https://dl.acm.org/doi/pdf/10.1145/320599.320696#page=2) describes the many types of objects and operations a UID can represent:

> The [Object Storage System] provides a flat space of objects (storage containers) addressed by unique identiilers (UIDs). Objects are typed, protected, abstract information containers: associated with each object is the UID of a type descriptor, the UID of an access control list (ACL) object, a disk storage descriptor, and some other attributes: length; date time created, used and modified; reference count; and so forth. Object types include: alphanumeric text, record structured data, IPC mailboxes, DBMS objects, executable modules, directories, access control lists, serial I/O ports, magnetic tape drives, and display bit maps. (Other objects which are not information containers also exist. UIDs are used to identify processes; and to identify persons, projects, organizations, and protected subsystems for authentication and protection purposes.) The distributed OSS makes the objects on each node accessible throughout the network (if the objects’ owners so choose by setting the objects’ ACLs appropriately). The operations provided by the OSS on storage objects include: creating, deleting, extending, and truneating an object; reading or writing a page of an object; getting and setting attributes of an object such as the ACL UID, type UID, and length: and locating the home node of an object.

> Programs access all objects by presenting their UIDs and asking for them to be "mapped” into the program’s address space.

> Another purpose [of the Single Level Store] is to provide a uniform, network transparent way to access objects: the mapping operation is independent of whether the UID is for a remote or local object.

> The Naming Server allows objects to be referred to by text string names. It manages a collectioti of directory objects which implements a hierarchical name space much like that of Multics or UNW [RITC 74]. The result is a uniform, network wide name space, in which objects have a unique canonical text string name as well as a UID. The name space supports convenient sharing, which would be severely hampered without the ability to uniformly name the objects to be shared among the sharing parties.

The structure of a UID is mentioned in [Identifying Objects using their UID](https://dl.acm.org/doi/pdf/10.1145/320599.320696#page=3):

> UIDs of objects are bit strings (64 bits long); they are made unique by concatenating the unique ID of the node generating the UID and a time stamp from the node’s timer. (The system does not use a global clock.) UlDs are also Jocation independent: the node ID in an object’s UID can not be considered as anything more than a hint about the current location of the object. (More detail on the use and implementation of UIDs is presented in [the 1982 document])

#### July

DOMAIN/IX UNIX becomes available as an addon for AEGIS Software Release 9.0 (SR9). I've taken this date from the printing of [Revision 00 of the domain/IX User's Guide](http://www.typewritten.org/Articles/Apollo/005803-00.pdf) which describes what DOMAIN/IX is. For reference, there is also a later [December 1986 revision of this User Guide](http://www.bitsavers.org/pdf/apollo/005803-01_DOMAIN_IX_Users_Guide_Dec86.pdf).

> DOMAIN/IX (pronounced “domain eye ex”) is an implementation of the UNIX operating system that runs on DOMAIN nodes.

> There are two versions of DOMAIN/IX. The `sys5` version is compatible with UNIX System V Release 2 from AT&T Bell Laboratories, and the `bsd4.2` version is compatible with 4.2 BSD, from the University of California at Berkeley. You may install either or both at your site.

> A DOMAIN system is comprised of two or more nodes connected by a high-speed (12Mbit/sec.) network. The network has a ring topology, and uses a token-passing protocol to prevent collisions between messages being sent from one node to another. Each node is a functional workstation, with its own central processor, memory, and memory management hardware. Programs and data required by processes running on a node are demand-paged across the network.

> DOMAIN/IX is co-resident with the domain system’s AEGIS operating system. Since they use many of the same underlying kernel functions, DOMAIN/IX and AEGIS are tightly integrated. As a result:
> - the UNIX programs supplied with DOMAIN/IX have the same file format as AEGIS programs
> - DOMAIN/IX UNIX shells can coexist on the same screen with AEGIS shells
> - UNIX commands can be executed by an AEGIS shell
> - AEGIS commands can be executed by a UNIX shell
>
> There is normally no distinction between processes that run UNIX programs and those that run other DOMAIN programs. UNIX programs and AEGIS programs can coexist within the same process, even within the same pipeline. There are only a few cases where naming conflicts (UNIX and AEGIS programs that have the same name) may make it necessary to rename or alias a command.

The term "UID" becomes overloaded at this point since `uid` is user ID in UNIX-land. The DOMAIN/IX User's Guide contains zero mention of any "UID" that is not in reference to UNIX-style user IDs.

### 1987

### Week of February 10

Apollo Computer announces public-domain Network Computing System (NCS)

CBR reports: [Apollo Aims to Change Face of Distributed Processing with Network Computing System](https://techmonitor.ai/technology/apollo_aims_to_change_face_of_distributed_processing_with_network_computing_system)

> Whether the Network Computing System — which has been put into the public domain by the Chelmsford, Massachusetts company — will do Apollo any more good than Ethernet has done Xerox or Unix has done AT&T, is another matter. If it really works as Apollo claims, the company will deserve all the success that comes to it — but the market is notoriously cruel to genuine innovators. Apollo describes the Network Computing System as the first commercially available set of distributed computing products for developing and running application programs across networks of incompatible computers from multiple vendors.

> In addition to unveiling generic tools for developing applications between dissimilar computers, Apollo introduced Network Computing System source code to run under Unix and DEC’s VAX/VMS. Network Computing System, needless to say written in C for maximum portability — C is also highly regarded as a system software programming language — is described as open and portable system. The source code can be licensed, is fully documented, and Apollo has published the specifications so that others can implement the system without having to pay Apollo for the privilege.

>  The system consists of three components that the company reckons solve the problems that previously prevented the development of true inter-vendor network computing — a Remote Procedure Call Run-time Environment — transparent to application programs — that handles packaging, transmission, reception of data, and error correction between the client and the parts of the application on the users’s workstation and on the computers providing remote services; Network Interface Definition Compiler, which compiles Apollo’s new high-level Network Interface Definition Language, NDL (shouldn’t that be NIDL, especially as Unisys-Burroughs already has an NDL?), into portable C source code that runs on both sides of the connection; and a Location Broker, which enables applications determine during program execution which remote computers on the network can provide the required services to the user’s computer.

#### June 8–12

[The Network Computing Architecture and System: An Environment for Developing Distributed Applications](https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz), T. H. Dineen, P. J. Leach, N. W. Mishkin, J. N. Pato, and G. L. Wyant, in Proceedings of the 1987 Summer USENIX Conference

We get a description of how NCA differs from NCS. TL;DR: NCA is the public-domain specification. NCS was Apollo's C implementation of that specification which could be licensed for cash money.

> The Network Computing Architecture (NCA) is an object-oriented framework for developing distributed applications. The Network Computing System™ (NCS™) is a portable implementation of that architecture that runs on Unix® and other systems.

> NCS currently runs under Apollo’s DOMAIN/IXT [Leach 83], 4.2BSD and 4.3BSD, and Sun’s version of Unix. Implementations are currently in progress for the IBM PCR and VAX/VMSR. Apollo Computer has placed NCA in the public domain.

> It supplies a transport-independent remote procedure call (RPC) facility using BSD sockets as the interface to any datagram facility.


[The new UUID structure](https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz#page=3) is introduced to identify interfaces, objects, operations, types, etc, and how it differs from the older AEGIS UIDs:

> An important aspect of NCA is its use of *universal unique identifiers* (UUIDs) as the most primitive means of identifying NCA entities (e.g. objects, interfaces, operations). UUIDs are an extension of the unique identifiers (UIDs) already used throughout Apollo’s system [Leach 82]. Both UIDs and UUIDs are fixed length identifiers that are guaranteed to refer to just one thing for all time. The principal advantages of using any kind of unique identifiers over using string names at the lowest level of the system include: small size, ease of embedding in data structures, location transparency, and the ability to layer various naming strategies on top of the primitive naming mechanism. Also, identifiers can be generated anywhere, without first having to contact some other agent (e.g. a special server on the network, or a human representative of a company that hands out identifiers).

> UIDs are 64 bits long and are guaranteed to be unique across all Apollo systems by embedding in them the node number of the system that generated the UID and the time on that system that the UID was generated. To make it possible to generate unique identifiers on non-Apollo system we defined UUIDs to be 128 bits and made the encoding of the identity of the system that generates the UUID more flexible.

It describes the [Network Interface Definition Language](https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz#page=5) and how it uses UUIDs to identify interfaces:

> A NIDL interface contains an header, constant and type definitions, and operation descriptions. The header provides the interface identification: its UUID, name, and version number. The UUID is the name by which an interface is known within NCA. It is similiar to the program number in other RPC systems, except that it is not centrally assigned. The interface name is a string name for the interface which is used by the NIDL compiler in naming certain publicly known variables. The version number is used to support compatible enhancements of interfaces.

It gives [an example](https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz#page=6) interface definition for "nbase/imp" with a UUID that looks a little different than the ones we know today!

> `[uuid(334033030000.0d.000.00.87.84.00.00.00), version(1)]`

It later describes how the [Location Broker](https://jim.rees.org/apollo-archive/papers/ncs.pdf.gz#page=10) finds interfaces based on their UUID:

> The NCA/LB, unlike location services like Xerox SDD's Clearing-house or Berkeley's Internet Name Domain service (BIND), yields location information based on UUIDs rather than on human readable string names. The advantages of using UUIDs were described earlier.

### 1988

#### January 6

[AT&T acquires 19% stake in Sun Microsystems](https://www.latimes.com/archives/la-xpm-1988-01-07-fi-33970-story.html)

#### February 17

CBR reports: [Apollo Positions Itself to Implement Emerging Standards with Domain/OS](https://techmonitor.ai/technology/apollo_positions_itself_to_implement_emerging_standards_with_domainos), describing the combined AEGIS+DOMAIN/IX Software Release 10 (SR10), now renamed Domain/OS.

> Apollo Computer Inc has extended the capabilities of its ambitious Network Computing System for interconnecting heterogeneous computer systems with the launch of a new operating system, Domain/OS, for its workstation product line. Domain/OS is a single system combining three operating environments — Unix System V.3, Berkeley 4.3, and Apollo’s proprietary AEGIS system, and also addresses criticisms that the company’s previous DOMAIN/IX implementation of Unix included a non-standard kernel.

#### February 29 – March 3

[The network computing architecture and system: an environment for developing distributed applications](https://ieeexplore.ieee.org/document/4877), T.H. Dineen; P.J. Leach; N.W. Mishkin; J.N. Pato; G.L. Wyant, COMPCON Spring 88 Thirty-Third IEEE Computer Society International Conference. [Available here](https://archive.org/details/compconspring8830000ieee/page/296/mode/2up?view=theater) free. It's identical to the '87 Summer USENIX paper.

#### May 17

Apollo Computer, DEC, HP, IBM, and three other companies form [Open Software Foundation](https://en.wikipedia.org/wiki/Open_Software_Foundation) with the intent of replacing all AT&T-derived code in their respective operating systems. See [Apollo VP Gives Inside Look at OSF Formation](https://books.google.com/books?id=9z4EAAAAMBAJ&lpg=PA33&vq=hamilton%20group%20osf&pg=PA33#v=onepage&q&f=false). This became the Mach-based [OSF/1](https://en.wikipedia.org/wiki/OSF/1).

#### July

[Using your Aegis Environment](http://bitsavers.org/pdf/apollo/SR10/011021-A00_Using_Your_Aegis_Environment_Jul88.pdf) contains no mention of UIDs or UUIDs but shows that the Aegis OS (title-cased now?) is still alive.

#### October

HP licenses NCS from Apollo.

CBR reports: [Apollo Wins Hewlett for Network Computing System](https://techmonitor.ai/technology/apollo_wins_hewlett_for_network_computing_system)

> Hewlett-Packard Co has followed IBM in taking a licence for Apollo Computer Inc’s Network Computing System, and is evaluating how to add it to Hewlett’s family of Unix computers.

### 1989

#### January

[Apollo Domain/OS Design Principles](https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf) describes the UUID's use in the [Network Interface Definition Language](https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf#page=116). It gives us [an example interface definition](https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf#page=118) with a UUID. It later describes how the [Location Broker](https://bitsavers.org/pdf/apollo/014962-A00_Domain_OS_Design_Principles_Jan89.pdf#page=126) finds interfaces based on their UUID. All of this is re-used verbatim from the 1987 Summer USENIX Conference paper (see above).

#### March 9

[Digital Equipment Joins Apollo Computer Effort](https://www.latimes.com/archives/la-xpm-1989-03-09-fi-1611-story.html)

> Apollo Computer Inc. and Digital Equipment Corp. said they are planning an expansion of Apollo’s Network Computing System.
> The companies said they will extend the system’s remote procedure call mechanism to support wide-area networking, large data-processing operations, international markets and additional network platforms and protocols.

#### April 12

[Hewlett-Packard acquires Apollo Computer](https://www.nytimes.com/1989/04/13/business/company-news-apollo-computer-sale-to-hewlett-packard.html)

### 1990

#### April

OSF chooses Apollo NCS as the basis of their shared Distributed Computing Environment.

#### October

CBR reports: [Open Software Foundation Blitz to Defend Distributed Computing Environment](https://techmonitor.ai/technology/open_software_foundation_blitz_to_defend_distributed_computing_environment)

> Since the Open Software Foundation’s choice of technology for its distributed Computing Environment was revealed at the end of April, a war of words has been going on within the industry between the Alternative Unix Club and supporters of rival methods for doing distributed computing. Open Software Foundation officials, Transarc Corp., and the Apollo arm of Hewlett-Packard Co have been talking to Unigram.X in an attempt to dispel the negative vibes thrown up around the – still nameless – Environment by some sections of the industry, and discuss what they regard as the technical advantages of the technology over other distributed computing environments, such as Sun Microsystems’ Open Network Computing Platform.

> Although they accept that the Network File System element of Open Network Computing – by virtue of its sheer installed base, which numbers upwards of 800,000 is something of a de facto standard in the market, they believe that Distributed Computing Environment offers additional functionality in areas where Open Network Computing comes up short.

### 1991

#### June

Microsoft hires [Paul J. Leach](https://www.linkedin.com/in/pauljleach) away from HP/Apollo.

#### June 3

[AT&T sells its Sun Microsystems stake](https://www.washingtonpost.com/archive/business/1991/06/04/att-sells-most-of-sun-microsystems-stake/dc9e19af-902c-4f33-a633-d4139ac73422/).

#### August

CBR reports:

> MICROSOFT GETS APOLLO CO-FOUNDER
>  Microsoft Corp has tapped Apollo Computer co-founder and designer of the company’s famous Network Computing System, Paul Leach to become its new director of future systems. 

### 1993

#### July 27

Windows NT 3.1 released, the first version of Windows to include MSRPC. TODO: Figure out what [build](https://betawiki.net/wiki/Windows_NT_3.1) included it first, since the earliest public NT 3.1 build is from September '91.

### 1996

#### September 7th

[e2fsprogs 1.05 adds `libuuid`](https://news.ycombinator.com/item?id=14509827) on Linux systems and [UUIDs are first added to ext2fs superblocks](https://www.spinics.net/lists/linux-xfs/msg72399.html)

#### November

https://datatracker.ietf.org/doc/html/draft-leach-cifs-v1-spec-01#section-4.1.1
https://web.archive.org/web/20230324102349/http://ubiqx.org/cifs/SMB.html

## Non-UUID specs

- https://github.com/ulid/spec
- https://github.com/rs/xid
- https://github.com/boundary/flake
- https://github.com/segmentio/ksuid


## Alternative Ruby Libraries

- `::SecureRandom::uuid` obviously
- https://github.com/sporkmonger/uuidtools
- https://github.com/assaf/uuid  /  https://www.rubydoc.info/gems/uuid/
- https://gist.github.com/brandur/1bddb5215540889983dc7e3a66ef4e41
- https://github.com/cassandra-rb/simple_uuid
- https://rubygems.org/gems/uuid4r
- https://api.rubyonrails.org/classes/Digest/UUID.html
